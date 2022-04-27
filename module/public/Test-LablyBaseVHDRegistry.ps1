Function Test-LablyBaseVHDRegistry {

    <#
    
    .SYNOPSIS

    Tests the Lably Base VHD registry.

    .DESCRIPTION

    This function is used to test to ensure that all of the Base VHDs in the registry exist and are valid.

    .PARAMETER Fix
    
    Switch to resolve issues with OS Edition and Version if found.

    .INPUTS

    None. You cannot pipe objects to Register-LablyBaseVHD.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    Test-LablyBaseVHDRegistry

    .EXAMPLE

    Test-LablyBaseVHDRegistry -Clean

    #>

    [CmdLetBinding(DefaultParameterSetName='VHD')]
    Param(
        [Parameter(Mandatory=$False)]
        [Switch]$Fix
    )    

    ValidateModuleRun -RequiresAdministrator

    $imageRegistryDirectory = Join-Path $env:USERPROFILE -ChildPath "Lably"
    $imageRegistry = Join-Path $imageRegistryDirectory -ChildPath "BaseImageRegistry.json"

    Try {
        Write-Verbose "Importing Existing Registry Directory"
        $RegistryObject = Get-Content $imageRegistry -Raw | ConvertFrom-Json
    } Catch {
        Throw "Could not load $imageRegistry. $($_.Exception.Message)"
    }

    $MountedVolumes = Get-Volume | Get-DiskImage | Select-Object -ExpandProperty ImagePath

    [Array]$BaseVHDsMounted = Compare-Object $RegistryObject.BaseImages.ImagePath $MountedVolumes -IncludeEqual | Where-Object { $_.SideIndicator -eq '==' }

    If($BaseVHDsMounted) {
        ForEach($VHD in $BaseVHDsMounted) {
            Write-Host "Dismount $($VHD.InputObject) before running test." -ForegroundColor Red
        }
        Throw "Cannot Test Base VHDs while they are mounted."
    }

    ForEach($VHD in $RegistryObject.BaseImages) {
        Write-Host "Testing $($VHD.ImagePath)"
        If(-Not(Test-Path $VHD.ImagePath)) {
            Write-Host "  Failed (File Doesn't Exist)" -ForegroundColor Red
            Write-Host "  You can manually resolve, or remove this item with:"
            Write-Host "  Unregister-LablyBaseVHD -Id $($VHD.Id)"
        } Else {
            Try {
                $mnt = Mount-VHD -Path $VHD.ImagePath -Passthru -ReadOnly -ErrorAction Stop
                $vhdDisk = $mnt | Get-Disk -ErrorAction Stop
                $vhdBasicPartition = Get-Partition $vhdDisk.DiskNumber -ErrorAction Stop | Where-Object { $_.Type -eq "Basic" -and $_.DriveLetter -ne "" }
                If(@($vhdBasicPartition).Count -gt 1) {
                    Write-Host " too many partitions." -ForegroundColor Yellow
                } else {
                    $VHDOSDriveLetter = $vhdBasicPartition.DriveLetter
                    $dismOutput = Start-ProcessGetStreams -FilePath $env:windir\system32\dism.exe -ArgumentList @("/Image:$VHDOSDriveLetter`:","/Get-CurrentEdition")

                    $imageVersion = [regex]::New("(?smi)Image Version: (\d{1,}.\d{1,}.\d{1,}.\d{1,})").Match($dismOutput.StdOut).Groups[1].Value
                    $imageEdition = [regex]::New("(?smi)Current Edition : (.*?)$").Match($dismOutput.StdOut).Groups[1].Value.ToString().Trim()
                
                    $RegistryValid = $True

                    If($vhd.OSName -ne "Windows") {
                        Write-Host "   OS in Registry is $($VHD.OSVersion) but OS is Windows." -NoNewline
                        If(-Not($Fix)) {
                            Write-Host " Use -Fix Parameter to Resolve Automatically."
                            $RegistryValid = $False
                        } Else {
                            Write-Host " Updating Registry."
                            $VHD.OSName = "Windows"
                        }
                    }

                    If($imageVersion -ne $vhd.OSVersion) {
                        Write-Host "   Image Version in Registry is $($VHD.OSVersion) but OS is $ImageVersion." -NoNewline
                        If(-Not($Fix)) {
                            Write-Host " Use -Fix Parameter to Resolve Automatically."
                            $RegistryValid = $False
                        } Else {
                            Write-Host " Updating Registry."
                            $VHD.OSVersion = $ImageVersion
                        }
                    }

                    If($imageEdition -ne $vhd.OSEdition) {
                        Write-Host "   Image Edition in Registry is $($VHD.OSEdition) but OS is $ImageEdition." -NoNewline
                        If(-Not($Fix)) {
                            Write-Host " Use -Fix Parameter to Resolve Automatically."
                            $RegistryValid = $False
                        } Else {
                            Write-Host " Updating Registry."
                            $VHD.OSEdition = $imageEdition
                        }
                    }

                    If($RegistryValid) {
                        $VHD.LastValidated = $(Get-DateUTC)
                    }

                    Dismount-VHD -Path $VHD.ImagePath -ErrorAction SilentlyContinue    
                }
            } Catch {
                Write-Host "  Failed. $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "  You can manually resolve, or remove this item with:"
                Write-Host "  Unregister-LablyBaseVHD -Id $($VHD.Id)"
                Dismount-VHD -Path $VHD.ImagePath -ErrorAction SilentlyContinue    
            }
        
        
        }
    }

    Try {
        Write-Verbose "Exporting Registry Data to $ImageRegistry"
        $RegistryObject.Meta.ModifiedDateUTC = (Get-DateUTC)
        $RegistryObject | ConvertTo-Json | Out-File $ImageRegistry -Force
    } Catch {
        Throw "Unable to save registry. $($_.Exception.Message)"
    }

}

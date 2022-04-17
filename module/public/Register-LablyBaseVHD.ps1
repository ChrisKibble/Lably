Function Register-LablyBaseVHD {
    [CmdLetBinding(DefaultParameterSetName='ProductKey')]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$VHD,

        [Parameter(Mandatory=$False)]
        [Int]$PartitionNumber,

        [Parameter(Mandatory=$False)]
        [String]$FriendlyName = "",

        [Parameter(Mandatory=$False,ParameterSetName='ProductKey')]
        [String]$ProductKey = "",

        [Parameter(Mandatory=$False,ParameterSetName='NoProductKey')]
        [Switch]$NoProductKey
    )    

    If(-Not($NoProductKey) -and $ProductKey -eq "") {
        Write-Host "You are encouraged to include a Product Key when registring. You may use KMS Client Keys from Here:" -ForegroundColor Yellow
        Write-Host "https://docs.microsoft.com/windows-server/get-started/kms-client-activation-keys" -ForegroundColor Yellow
        Write-Host "To Skip using a Product Key, use the -NoProductKey Parameter" -ForegroundColor Yellow
        Write-Host ""
        Throw "Missing Product Key"
    }

    If($NoProductKey) {
        Write-Host "You are encouraged to include a Product Key when registring. You may use KMS Client Keys from Here:" -ForegroundColor Yellow
        Write-Host "You may need to manually enter a product key when building VMs from this base image." -ForegroundColor Yellow
    }

    Try {
        Write-Host "Mounting $VHD to gather Image Details"
        $vhdMount = Mount-VHD -Path $VHD -Passthru -ErrorAction Stop
    } Catch {
        Throw "Unable to Mount VHD. $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Getting Disks of $VHD"
        $vhdDisk = $vhdMount | Get-Disk
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Throw "Unable to Get Disk from VHD. $($_.Exception.Message)"
    }
    
    Try {
        Write-Verbose "Getting Partitions from Disk #$($vhdDisk.Number)"
        $vhdBasicPartition = Get-Partition $vhdDisk.DiskNumber -ErrorAction Stop | Where-Object { $_.Type -eq "Basic" -and $_.DriveLetter -ne "" }
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Throw "Unable to get basic partitions with disk letters from VHD. $($_.Exception.Message)"
    }

    If(-Not($vhdBasicPartition)) {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Throw "No basic partitions found in $VHD"
    }

    If($PartitionNumber) {
        $vhdBasicPartition = $vhdBasicPartition | Where-Object { $_.PartitionNumber -eq $PartitionNumber }
        If(-Not($vhdBasicPartition)) {
            Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
            Throw "Could not find basic partition #$PartitionNumber in $VHD"
        }
    } else {
        If(@($vhdBasicPartition).Count -gt 1) {
            Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
            Throw "There is more than one basic partition in $VHD. Use -PartitionNumber to define which one to use."
        }
    }

    $VHDOSDriveLetter = $vhdBasicPartition[0].DriveLetter

    Try {
        Write-Verbose "Getting Windows Image Information from $VHDOSDriveLetter"
        $dismOutput = Start-ProcessGetStreams -FilePath $env:windir\system32\dism.exe -ArgumentList @("/Image:$VHDOSDriveLetter`:","/Get-CurrentEdition")

        Write-Verbose "stdOut: $($dismOutput.StdOut)"
        Write-Verbose "stdErr: $($dismOutput.StdErr)"
        Write-Verbose "Exit Code: $($dismOutput.ExitCode)"

        If($dismOutput.ExitCode -ne 0) {
            Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue    
            Throw "DISM Ended with Non-Zero Exit Code $($dismOutput.ExitCode)"
        }
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Throw "Unable to get DISM output. $($_.Exception.Message)"
    }

    $imageVersion = [regex]::New("(?smi)Image Version: (\d{1,}.\d{1,}.\d{1,}.\d{1,})").Match($dismOutput.StdOut).Groups[1].Value
    $imageEdition = [regex]::New("(?smi)Current Edition : (.*?)$").Match($dismOutput.StdOut).Groups[1].Value.ToString().Trim()

    If(-Not($imageVersion -as [Version])) {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Throw "Image Version ($imageVersion) is not a valid version number."
    }

    If(-Not($imageEdition)) {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Throw "No Image Edition identified in VHD."
    }

    Write-Verbose "Image Version is $imageVersion and Image Edition is $imageEdition."

    Try {
        Write-Verbose "Dismounting $VHD"
        Dismount-Vhd -Path $VHD -ErrorAction Stop
    } Catch {
        Write-Warning "Could not dismount $VHD, you'll need to manually dismount or reboot before using. $($_.Exception.Message)"
    }

    $imageRegistryDirectory = Join-Path $env:USERPROFILE -ChildPath "Lably"
    $imageRegistry = Join-Path $imageRegistryDirectory -ChildPath "BaseImageRegistry.json"

    If(-Not(Test-Path $imageRegistryDirectory)) {
        Try {
            Write-Verbose "Creating $imageRegistryDirectory"
            New-Item -ItemType Directory -Path $imageRegistryDirectory -ErrorAction Stop | Out-Null
        } Catch {
            Throw "Could not create $imageRegistryDirectory. $($_.Exception.Message)"
        }
    }

    If(Test-Path $imageRegistry) {
        Try {
            Write-Verbose "Importing Existing Registry Directory"
            $RegistryObject = Get-Content $imageRegistry -Raw | ConvertFrom-Json
        } Catch {
            Throw "Could not load $imageRegistry. $($_.Exception.Message)"
        }
    }

    If(-Not($RegistryObject)) {
        Write-Verbose "Creating New Registry Object"
        $RegistryObject = @{
            "Meta" = @{
                "Comment" = "This is your Lably Registry that points to your base images that labs can use to build labs. There's no value in sharing this file, it's meant for this PC."
                "CreatedDateUTC" = $(Get-DateUTC)
                "Version" = "0.1"
            }
        } | ConvertTo-Json | ConvertFrom-Json
    }

    If(-Not($RegistryObject.BaseImages)) {
        Add-Member -InputObject $RegistryObject -MemberType NoteProperty -Name "BaseImages" -Value @()
    }

    [System.Collections.ArrayList]$BaseImages = @($RegistryObject.BaseImages)

    $BaseImages.Add(
        @{
            "FriendlyName" = $FriendlyName
            "Id" = [guid]::NewGuid()
            "ImagePath" = $VHD
            "OSName" = "Windows"
            "OSVersion" = $imageVersion
            "OSEdition" = $imageEdition
            "DateAdded" = $(Get-DateUTC)
            "LastValidated" = $(Get-DateUTC)
            "ProductKey" = $ProductKey
        }
    ) | Out-Null

    $RegistryObject.BaseImages = $BaseImages

    Add-Member -InputObject $RegistryObject.Meta -MemberType NoteProperty -Name "ModifedDateUTC" -Value $(Get-DateUTC) -Force

    Try {
        Write-Verbose "Exporting Registry Data to $ImageRegistry"
        $RegistryObject | ConvertTo-Json | Out-File $ImageRegistry -Force
    } Catch {
        Throw "Unable to save registry. $($_.Exception.Message)"
    }

    Write-Host "BaseVHD has been registered."
}

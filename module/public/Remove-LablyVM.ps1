Function Remove-LablyVM {

    <#
    
    .SYNOPSIS

    Remove a VM from Lably and from Hyper-V.

    .DESCRIPTION

    This function is used to remove a VM from Lably and from Hyper-V.

    .PARAMETER Path
    
    Optional parameter to define where the lably that this VM is a member of is stored. If this parameter is not defined, it will default to the path from which the function was called.

    .PARAMETER DisplayName

    Display Name of the VM to be removed. Either this or the VMID parameter is required. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .PARAMETER VMID

    Lably ID of the VM to be removed. Either this or the DisplayName parameter is required.

    .PARAMETER Confirm

    Optional Switch to bypass confirming that you want to delete the Virtual Machine.

    .INPUTS

    None. You cannot pipe objects to Remove-LablyVM.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    Remove-LablyVM -DisplayName "[Chris' Lab] LABDC01"

    .EXAMPLE

    Remove-LablyVM -VMID 717b54e6-a50a-480e-8a3f-9f21ab2e08e9

    #>

    [CmdLetBinding(DefaultParameterSetName='DisplayName')]
    Param(
        [Parameter(Mandatory=$False)]    
        [String]$Path = $PWD,

        [Parameter(Mandatory=$True,ParameterSetName="DisplayName",Position=0)]
        [String]$DisplayName,

        [Parameter(Mandatory=$True,ParameterSetName='VMID',Position=0)]
        [String]$VMId,

        [Parameter(Mandatory=$False)]
        [Switch]$Confirm
    )

    $LablyScaffold = Join-Path $Path -ChildPath "scaffold.lably.json"
    Write-Verbose "Reading Lably Scaffolding File at $LablyScaffold"

    If(-Not(Test-Path $LablyScaffold -ErrorAction SilentlyContinue)){
        Throw "There is no Lably at $Path."
    }

    Try {
        $Scaffold = Get-Content $LablyScaffold | ConvertFrom-Json
    } Catch {
        Throw "Unable to import Lably scaffold. $($_.Exception.Message)"
    }

    $Asset = $Scaffold.Assets | Where-Object { $_.DisplayName -eq $DisplayName -or $_.VMid -eq $VMID } | Select-Object -First 1
       
    If(-Not($Asset)) {
        Throw "Cannot find defined VM in this Lably."
    }

    Try {
        $VM = Get-VM -Id $Asset.VMId -ErrorAction Stop
    } Catch {
        Write-Warning "Warning: Cannot Find VM, Skipping. $($_.Exception.Message)"
    }

    If($VM) {
        
        If(-Not($Confirm)) {
            Write-Host "You are about to delete $($VM.Name)"
            Write-Host "This operation cannot be undone." -ForegroundColor Red
            Write-Host ""
            If($(Read-Host "If you're certain you'd like to continue, type DELETE and press enter") -ne "DELETE") {
                Write-Host "Code 'DELETE' was not entered. Aborting." -ForegroundColor Yellow
                Return
            }
        }

        Write-Host "Stopping VM"
        Try {
            $VM | Stop-VM -Force -TurnOff -ErrorAction Stop -WarningAction SilentlyContinue
        } Catch {
            Throw "Could not stop VM. $($_.Exception.Message)"
        }

        Write-Verbose "State of $($VM.Name) is $($VM.State). Status is $($VM.Status)."

        While($VM.State -ne [Microsoft.HyperV.PowerShell.VMState]::Off -and $VM.Status -ne "Operating Normally") {
            Write-Verbose "Waiting for VM to Stop (State=$($VM.State) Status=$($VM.Status))..."
            Start-Sleep -Seconds 1
        }

        $ActivityStart = Get-Date
        $RunTime = New-TimeSpan -Start $ActivityStart -End (Get-Date)
        While(@($VM | Get-VMHardDiskDrive | Select-Object -ExpandProperty Path) -like "*.avhdx" -or $RunTime.TotalMinutes -ge 1) {
            Write-Verbose "Waiting for Disk Merging Activities to Complete ..."
            Start-Sleep -Seconds 1
            $RunTime = New-TimeSpan -Start $ActivityStart -End (Get-Date)
        }

        $VHDPaths = @()

        $VM | Get-VMHardDiskDrive | ForEach-Object { 
            Write-Host "Deleting $($_.Path) ..."
        
            $VHDPaths += Split-Path $_.Path

            $AttemptNumber = 0
            $MaxAttempts = 5

            Do {
                Try {
                    $FileDeleteSuccess = $False
                    $AttemptNumber++
                    Remove-Item $($_.Path) -Force -ErrorAction Stop
                    $FileDeleteSuccess = $True
                } Catch {
                    # In edge cases, VHDx is still merging even though status doesn't seem to show that's the case. The file
                    # appears to be held in use for an extra second or so.
                    Write-Warning "Could not delete $($_.Path) (Attempt $AttemptNumber of $MaxAttempts)."
                    If($Attempt -eq $MaxAttempt) { Write-Warning $($_.Exception.Message) }
                    Start-Sleep -Seconds 5
                }    
            } Until ($FileDeleteSuccess -or $AttemptNumber -eq $MaxAttempts)
        }

        Write-Host "Removing VM $($VM.Name)"

        Try {
            $VM | Remove-VM -Force
        } Catch {
            Write-Warning "Could not delete $($VM.Name). $($_.Exception.Message)"            
        }      
    }
    
    ForEach($VHDPath in $VHDPaths) {
        Write-Verbose "Clearing $VHDPath (If Empty)"
        If(-Not (Get-ChildItem $VHDPath | Select-Object -First 1)) { Remove-Item $VHDPath -ErrorAction SilentlyContinue }
    }

    Try {
        $Scaffold = Get-Content $LablyScaffold | ConvertFrom-Json
        $Scaffold.Assets = $Scaffold.Assets | Where-Object { $_.VMId -ne $Asset.VMid }
        $Scaffold | ConvertTo-Json -Depth 10 | Out-File $LablyScaffold -Force
    } Catch {
        Write-Warning "VM is removed but we were unable to remove it from your Lably scaffoling."
        Write-Warning $_.Exception.Message
    }

   Write-Host "Done."

}
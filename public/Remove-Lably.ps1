Function Remove-Lably {

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$False)]    
        [String]$Path = $PWD,

        [Parameter(Mandatory=$False)]
        [Switch]$Confirm
    )

    ##TODO: Remove switch if nothing else is using it (with param to skip this?)

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

    $VHDPath = $Scaffold.Meta.VirtualDiskPath
    $KeyFile = $Scaffold.Meta.KeyFile
    $Assets = $Scaffold.Assets

    $VMsToDestroy = ForEach($Asset in $Assets) {
        Get-VM -id $Asset.VMId
    }

    If(-Not($Confirm)) {
        Write-Host "WARNING! You are about to delete your Lably." -ForegroundColor Red
        Write-Host ""
        Write-Host "This will also stop and delete the following VMs and their associated disks:"
        ForEach($VM in $VMsToDestroy) { Write-Host " - $($VM.Name) ($($VM.VmId))" }
        Write-Host ""
        Write-Host "Your current scaffold ($LablyScaffold) will also be removed."
        Write-Host ""
        Write-Host "Any virtual switches and BaseVHDs will not be destroyed."
        Write-Host ""
        Write-Host "This operation cannot be undone." -ForegroundColor Red
        Write-Host ""
        If($(Read-Host "If you're certan you'd like to continue, type DESTROY and press enter") -ne "DESTROY") {
            Write-Host "Code 'DESTROY' was not entered. Aborting." -ForegroundColor Yellow
            Return
        }
    }

    Write-Host "Stopping All VMs ..."
    Stop-Lably -Path $Path -TurnOff -Force

    Start-Sleep -Seconds 1

    ForEach($VM in $VMsToDestroy) {
        Write-Verbose "State of $($VM.Name) is $($VM.State). Status is $($VM.Status)."
        While($VM.State -ne [Microsoft.HyperV.PowerShell.VMState]::Off -and $VM.Status -ne "Operating Normally") {
            Write-Verbose "Waiting for VM to Stop (State=$($VM.State) Status=$($VM.Status))..."
            Start-Sleep -Seconds 1
        }
        $VM | Get-VMHardDiskDrive | ForEach-Object { 
            Write-Host "Deleting $($_.Path) ..."
            Try {
                Remove-Item $($_.Path) -Force -ErrorAction Stop
            } Catch {
                Write-Warning "Could not delete $($_.Path). $($_.Exception.Message)"
            }
        }
        Write-Host "Removing VM $($VM.Name)"
        Try {
            $VM | Remove-VM -Force
        } Catch {
            Write-Warning "Could not delete $($VM.Name). $($_.Exception.Message)"            
        }      
    }

    Write-Host "Deleting Scaffold ($LablyScaffold)"
    Try {
        Remove-Item $LablyScaffold -Force
    } Catch {
        Write-Warning "Could not Scaffold. $($_.Exception.Message)"
    }

    Write-Host "Removing Empty Folders from $VHDPath"
    Get-ChildItem $VHDPath -Recurse -Force -Directory | Sort-Object -Property FullName -Descending | Where-Object { $($_ | Get-ChildItem -Force | Select-Object -First 1).Count -eq 0 } | Remove-Item -ErrorAction SilentlyContinue
    If(-Not (Get-ChildItem $VHDPath | Select-Object -First 1)) { Remove-Item $VHDPath -ErrorAction SilentlyContinue }
    
    If(-Not (Get-ChildItem $Path | Select-Object -First 1)) { 
        Write-Host "Removing $Path"
        Remove-Item $Path -ErrorAction SilentlyContinue
    } Else {
        Write-Host "There are files/folders left over in $Path. Will not remove."
    }

    If($KeyFile) {
        Write-Host "Your KeyFile has not been deleted. If you no longer require it, you may delete it manually."
        Write-Host $KeyFile
    }

    Write-Host "Done."

}
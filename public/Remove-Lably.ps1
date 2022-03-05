Function Remove-Lably {

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$False)]    
        [String]$Path = $PWD,

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

    $VHDPath = $Scaffold.Meta.VirtualDiskPath
    $KeyFile = $Scaffold.Meta.KeyFile
    $Assets = $Scaffold.Assets
    $SwitchId = $Scaffold.Meta.SwitchId
    $TemplatePath = Join-Path $Path -ChildPath "Template Cache"

    If(-Not($Confirm)) {
        Write-Host "WARNING! You are about to delete your Lably." -ForegroundColor Red
        Write-Host ""
        Write-Host "This will also stop and delete the following VMs and their associated disks:"
        ForEach($Asset in $Assets) { Write-Host " - $($Asset.DisplayName) ($($Asset.VmId))" }
        Write-Host ""
        Write-Host "Your current scaffold ($LablyScaffold) will be removed."
        If(Test-Path $TemplatePath) {
            Write-Host "Your Template Cache ($TemplatePath) will be removed."
        }
        Write-Host ""
        Write-Host "This operation cannot be undone." -ForegroundColor Red
        Write-Host ""
        If($(Read-Host "If you're certan you'd like to continue, type DESTROY and press enter") -ne "DESTROY") {
            Write-Host "Code 'DESTROY' was not entered. Aborting." -ForegroundColor Yellow
            Return
        }
    }

    ForEach($Asset in $Assets) {
        Remove-LablyVM -Path $Path -VMId $Asset.VMId -Confirm | Out-Null
    }

    $SwitchName = Get-VMSwitch -Id $SwitchId | Select-Object -ExpandProperty Name
    If(-Not(Get-VMNetworkAdapter -All | Where-Object { $_.SwitchName -eq $SwitchName -and $_.VMName })) {
        Write-Host "Removing Switch $SwitchName"
        Get-VMSwitch -Id $SwitchId | Remove-VMSwitch -Force
    } Else {
        Write-Host "Will not remove virtual switch as it's being used by other VMs."
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

    Remove-Item $TemplatePath -ErrorAction SilentlyContinue -Recurse -Force

    If($KeyFile) {
        Write-Host "Your KeyFile has not been deleted. If you no longer require it, you may delete it manually."
        Write-Host $KeyFile
    }

    Write-Host "Done."

}
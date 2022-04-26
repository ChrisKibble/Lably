Function Remove-Lably {

    <#
   
    .SYNOPSIS

    Remove an existing lab in the current directory or defined path.

    .DESCRIPTION

    This function is used to remove a Lably from the current directory or defined path. It will also remove the VMs from Hyper-V and cleanup everything associated with the lab.

    .PARAMETER Path
    
    Optional parameter to define where the lably is stored. If this parameter is not defined, it will default to the path from which the function was called.

    .PARAMETER Name

    Optional name of the Lably. Used as a description when using and describing the lab, as well as the default prefix for the display name of VMs created in Hyper-V. If this parameter is not defined, it will default to the name of the folder it's being created it.

    .PARAMETER Confirm

    Optional Switch to bypass confirming that you want to delete the Lab and associated data.

    .INPUTS

    None. You cannot pipe objects to New-Lably.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    Remove-Lably

    .EXAMPLE

    Remove-Lably -Path C:\Labs\Windows10-Lab

    #>

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$False)]    
        [String]$Path = $PWD,

        [Parameter(Mandatory=$False)]
        [Switch]$Confirm
    )

    ValidateModuleRun -RequiresAdministrator

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
    $SwitchCreated = $Scaffold.Meta.SwitchCreated
    $TemplatePath = Join-Path $Path -ChildPath "Template Cache"
    $NetNAT = $Scaffold.Meta.NATName

    $SwitchName = Get-VMSwitch -Id $SwitchId | Select-Object -ExpandProperty Name

    If(-Not($Confirm)) {
        Write-Host "WARNING! You are about to delete your Lably." -ForegroundColor Red
        Write-Host ""
        Write-Host "This will also stop and delete the following VMs and their associated disks:"
        ForEach($Asset in $Assets) { Write-Host " - $($Asset.DisplayName) ($($Asset.VmId))" }
        Write-Host ""
        If($NetNAT) { Write-Host "Your NAT '$NetNAT' will be deleted."; Write-Host "" }
        If($SwitchCreated) { Write-Host "VM Switch $SwitchName will be removed"}
        Write-Host "Your Template Cache ($TemplatePath) will be removed."
        Write-Host "Your current scaffold ($LablyScaffold) will be removed."
        Write-Host ""
        Write-Host "This operation cannot be undone." -ForegroundColor Red
        Write-Host ""
        If($(Read-Host "If you're certain you'd like to continue, type DESTROY and press enter") -ne "DESTROY") {
            Write-Host "Code 'DESTROY' was not entered. Aborting." -ForegroundColor Yellow
            Return
        }
    }

    ForEach($Asset in $Assets) {
        Remove-LablyVM -Path $Path -VMId $Asset.VMId -Confirm | Out-Null
    }

    If($SwitchCreated) {

        If(-Not(Get-VMNetworkAdapter -All | Where-Object { $_.SwitchName -eq $SwitchName -and $_.VMName })) {
            Write-Host "Removing Switch $SwitchName"
            Get-VMSwitch -Id $SwitchId | Remove-VMSwitch -Force
        } Else {
            Write-Host "Will not remove virtual switch as it's being used by other VMs."
        }

    }

    If($NetNAT) {
        Write-Host "Deleting NAT '$NetNAT'"
        Try {
            Get-NetNat -Name $NetNAT | Remove-NetNAT -Confirm:$False -ErrorAction Stop
        } Catch {
            Write-Warning "Could not removed NAT. $($_.Exception.Message)"
        }
    }

    Write-Host "Clearing Cached Templates from $TemplatePath"
    
    ForEach($CachedTemplate in (Get-ChildItem -Path $TemplatePath -Filter *.json -ErrorAction SilentlyContinue)) {
        Try {
            Remove-Item $CachedTemplate
        } Catch {
            Write-Warning "Could not delete $CachedTemplate. $($_.Exception.Message)"
        }
    }

    If(-Not (Get-ChildItem $TemplatePath -ErrorAction SilentlyContinue | Select-Object -First 1)) { 
        Write-Host "Removing $TemplatePath"
        Try {
            Remove-Item $TemplatePath -ErrorAction SilentlyContinue
        } Catch {
            Write-Warning "Could not remove $TemplatePath. You may need to manually delete this folder."
        }       
    } Else {
        Write-Host "There are files/folders left over in $TemplatePath. Will not remove."
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
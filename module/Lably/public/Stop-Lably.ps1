Function Stop-Lably {

    <#
    
    .SYNOPSIS

    Starts all of the Virtual Machines that are members of the defined lably.

    .DESCRIPTION

    This function is used to start all of the Virtual Machines that are members of the defined lably.

    .PARAMETER Path
    
    Optional parameter to define where the lably is stored. If this parameter is not defined, it will default to the path from which the function was called.

    .PARAMETER Force
    
    Switch that tells Hyper-V to force the shutdown of the VMs, even when the OS identifies processes that prevent shutdown.

    .PARAMETER Force
    
    Switch that tells Hyper-V to turn the VMs off instead of the normal shutdown.
    
    .INPUTS

    None. You cannot pipe objects to Stop-Lably.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    Stop-Lably

    #>

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD,
        
        [Parameter(Mandatory=$False)]
        [Switch]$Force,
        
        [Parameter(Mandatory=$False)]
        [Switch]$TurnOff
    )

    ValidateModuleRun -RequiresAdministrator

    $LablyScaffold = Join-Path $Path -ChildPath "scaffold.lably.json"
    $Scaffold = Import-LablyScaffold -LablyScaffold $LablyScaffold -ErrorAction Stop

    ForEach($Asset in $Scaffold.Assets) {
        Try {
            $VM = Get-VM -Id $Asset.VMId
            If(-Not($VM)) {
                Write-Warning "VM with ID '$($Asset.VMID)' does not exist."
            } Else {
                If($VM.State -eq [Microsoft.HyperV.PowerShell.VMState]::Running) {
                    Write-Host "Stopping $($VM.Name) with Force=$Force"
                    $VM | Stop-VM -Force:$Force -TurnOff:$TurnOff
                } Else {
                    Write-Verbose "$($VM.Name) is not in state 'Running'.  State is '$($VM.State)'"
                }
            }
        } Catch {
            Write-Warning "Could not stop $($Asset.DisplayName) - $($_.Exception.Message)"
        }
    }

}
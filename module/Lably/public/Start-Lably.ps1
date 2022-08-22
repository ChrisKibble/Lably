Function Start-Lably {

    <#
    
    .SYNOPSIS

    Starts all of the Virtual Machines that are members of the defined lably.

    .DESCRIPTION

    This function is used to start all of the Virtual Machines that are members of the defined lably.

    .PARAMETER Path
    
    Optional parameter to define where the lably is stored. If this parameter is not defined, it will default to the path from which the function was called.

    .INPUTS

    None. You cannot pipe objects to start-Lably.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    Start-Lably

    #>

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD
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
                If($VM.State -eq [Microsoft.HyperV.PowerShell.VMState]::Off) {
                    Write-Host "Starting $($VM.Name)"
                    $VM | Start-VM
                    If($DelaySeconds -gt 0) {
                        Write-Verbose "Sleeping $DelaySeconds Seconds"
                        Start-Sleep -Seconds $DelaySeconds
                    }
                } Else {
                    Write-Verbose "$($VM.Name) is not in state 'OFF'.  State is '$($VM.State)'"
                }
            }
        } Catch {
            Write-Warning "Could not start $($Asset.DisplayName) - $($_.Exception.Message)"
        }
    }

}
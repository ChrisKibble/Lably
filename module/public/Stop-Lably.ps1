Function Stop-Lably {

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD,
        
        [Parameter(Mandatory=$False)]
        [Switch]$Force,
        
        [Parameter(Mandatory=$False)]
        [Switch]$TurnOff
    )

    $LablyScaffold = Join-Path $Path -ChildPath "scaffold.lably.json"
    Write-Verbose "Reading Lably Scaffolding File at $LablyScaffold"

    If(-Not(Test-Path $LablyScaffold -ErrorAction SilentlyContinue)){
        Throw "There is no Lably at $Path."
    }

    Try {
        $Scaffold = Get-Content $LablyScaffold
    } Catch {
        Throw "Unable to import Lably scaffold. $($_.Exception.Message)"
    }

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
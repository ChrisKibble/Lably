Function Start-Lably {

    [CmdLetBinding()]
    Param(
        [String]$Path = $PWD,
        [Int]$DelaySeconds = 0
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
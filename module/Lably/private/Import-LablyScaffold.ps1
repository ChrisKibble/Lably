
Function Import-LablyScaffold {

    [CmdLetBinding()]
    Param(
        [String]$LablyScaffold
    )

    If(-Not(Test-Path $LablyScaffold -ErrorAction SilentlyContinue)){
        Throw "There is no Lably at $Path."
    }

    Try {
        $Scaffold = Get-Content $LablyScaffold | ConvertFrom-Json
    } Catch {
        Throw "Unable to import Lably scaffold. $($_.Exception.Message)"
    }

    If(-Not($Scaffold.Meta.SwitchId)) {
        Throw "Lably Scaffold missing SwitchId. File may be corrupt."
    }

    Return $Scaffold

}
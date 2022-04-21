Function ValidateModuleRun {

    [CmdLetBinding()]
    Param(
        [Switch]$RequiresAdministrator
    )

    If(-Not(Get-Module Hyper-V -ErrorAction SilentlyContinue)) {
        Try {
            Import-Module Hyper-V -ErrorAction Stop
        } Catch {
            Throw "Could not load the required Hyper-V module."
        }
    }

    If($RequiresAdministrator) {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        If(-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Throw "This function requires administrator rights."
        }
    }


}
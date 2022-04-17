Function Get-LablyTemplate {

    [CmdLetBinding()]
    Param(
        [String]$TemplateFile
    )

    Try {
        $Template = Get-Content $TemplateFile | ConvertFrom-Json
    } Catch {
        Throw "Unable to read Template. $($_.Exeption.Message)"
    }

    Return $Template

}
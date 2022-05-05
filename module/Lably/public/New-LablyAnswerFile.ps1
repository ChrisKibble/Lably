Function New-LablyAnswerFile {

    <#
    
    .SYNOPSIS

    Creates a new answer file for a template.

    .DESCRIPTION

    This function is used create an answer file that can be passed to New-LablyVM as a parameter to answer the questions posed by a template.

    .PARAMETER Template

    Template to be used. Templates will be loaded from the "Templates" subfolder of the module and custom ones can be installed into the Lably\Templates folder of the user profile. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .INPUTS

    None. You cannot pipe objects to New-LablyAnswerFile.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.

    .EXAMPLE

    New-LablyAnswerFile -Template "My Template Name" | Out-File c:\AnswerFiles\TemplateAnswerFile.json

    #>

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Template,
        
        [Parameter(Mandatory=$False)]
        [Switch]$IncludeHelpMessages
    )

    # User Template over Module Template - Look at User Templates First
    $UserTemplateFile = Join-Path $env:UserProfile -ChildPath "Lably\Templates\$Template.json"
    $ModuleTemplateFolder = Join-Path (Split-Path $PSScriptRoot) -ChildPath "Templates"
    $ModuleTemplateFile = Join-Path $ModuleTemplateFolder -ChildPath "$Template.json"

    If(Test-Path $UserTemplateFile) {
        $TemplateFile = $UserTemplateFile
    } ElseIf(Test-Path $ModuleTemplateFile) {
        $TemplateFile = $ModuleTemplateFile
    } else {
        Throw "Cannot find $Template"
    }

    $LablyTemplate = Get-LablyTemplate $TemplateFile

    $PromptList = @{}

    ForEach($TemplatePrompt in ($LablyTemplate.Input | Get-Member -Type Properties)) {
        $PromptName = $TemplatePrompt.Name

        $PromptList.Add($PromptName, $null)

    }
 
    $PromptList | ConvertTo-Json

}
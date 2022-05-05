Function New-LablyAnswerFile {

    <#
    
    .SYNOPSIS

    Creates a new answer file for a template.

    .DESCRIPTION

    This function is used create an answer file that can be passed to New-LablyVM as a parameter to answer the questions posed by a template.

    .PARAMETER Template

    Template to be used. Templates will be loaded from the "Templates" subfolder of the module and custom ones can be installed into the Lably\Templates folder of the user profile. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .PARAMETER IncludeHelpMessages

    Optional switch that will include a copy of the prompt questions and validation messages to help identify the purpose of the question.

    .INPUTS

    None. You cannot pipe objects to New-LablyAnswerFile.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.

    .EXAMPLE

    New-LablyAnswerFile -Template "My Template Name" | Out-File c:\AnswerFiles\TemplateAnswerFile.json

    .EXAMPLE

    New-LablyAnswerFile -Template "My Template Name" -IncludeHelpMessages | Out-File c:\AnswerFiles\TemplateAnswerFile.json

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

    $AnswerFile = [PSCustomObject]@{
        Meta = @{
            About = "This is a Lably AnswerFile."
            Schema = "0.1"
        }
    }

    $AnswerFile = ForEach($TemplatePrompt in ($LablyTemplate.Input | Get-Member -Type Properties)) {
        $PromptName = $TemplatePrompt.Name
        $PromptQuestions = $LablyTemplate.Input.$PromptName.Prompt
        $ValidationMessages = $LablyTemplate.Input.$PromptName.Validate.Message
        $ValidationRegEx = $LablyTemplate.Input.$PromptName.Validate.RegEx
            
        $Help = @{
            Prompts = $PromptQuestions
            ValidationRegEx = $ValidationRegEx
            ValidationMessages = $ValidationMessages
        }

        $PromptObject = [PSCustomObject]@{
            PromptName = $PromptName
            Answer = $null
        }

        If($IncludeHelpMessages) {
            Add-Member -InputObject $PromptObject -MemberType NoteProperty -Name Help -Value $Help
        }

        $PromptObject
    }
    
    $AnswerFile | ConvertTo-Json -Depth 10

}
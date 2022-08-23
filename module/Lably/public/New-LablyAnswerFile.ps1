Function New-LablyAnswerFile {

    <#
    
    .SYNOPSIS

    Creates a new answer file for a template.

    .DESCRIPTION

    This function is used create an answer file that can be passed to New-LablyVM as a parameter to answer the questions posed by a template.

    .PARAMETER Template

    Template to be used. Templates will be loaded from the "Templates" subfolder of the module and custom ones can be installed into the Lably\Templates folder of the user profile. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

   .PARAMETER IncludeHelperMessages

    Help messages will be exported to the JSON file to make it easier to fill out. These can be removed after the template has been filled out, however they will not impact a new VM build if left inside the JSON file.

    .PARAMETER CompressJson

    Resulting JSON will be compressed instead of broken up by line. This is the equivalent of `ConvertTo-Json -Compress`.

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
        [Switch]$IncludeHelpMessages,

        [Parameter(Mandatory=$False)]
        [Switch]$CompressJson
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

    $PromptList = [Ordered]@{}

    ForEach($PromptName in ($LablyTemplate.input[0].psobject.properties.name)) {
        $PromptList.Add($PromptName, $null)

        If($IncludeHelpMessages) {
            ForEach($PromptMsg in $LablyTemplate.Input."$PromptName".prompt.psobject.properties) {
                [Boolean]$PromptSecure = $LablyTemplate.Input."$PromptName".Secure
                $ValidateRegEx = $LablyTemplate.Input."$PromptName".Validate.RegEx

                $PromptList.Add("$($PromptName)_#HelpMsg-$($PromptMsg.Name)", $PromptMsg.Value)
                $PromptList.Add("$($PromptName)_#Secure", $PromptSecure)
                $PromptList.Add("$($PromptName)_#ValidationRegEx", $ValidateRegEx)
            }
        }
    }
 
    $PromptList | ConvertTo-Json -Compress:$CompressJson

}
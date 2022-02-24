Function Literalize {

    [CmdLetBinding()]
    Param(
        [Array]$InputResponse,
        [String]$InputData
    )

    ##TODO: Should probably have an escape character.

    Write-Verbose "Literalizing $InputData"

    # Replace all variables with plain text

    $VariableList = [Regex]::New("(?msi)\[\[(\w{1,})\]\]").Matches($InputData)

    ForEach($V in $VariableList) {        
        $SearchString = $V.Groups[0].Value
        $ReplaceKey = $V.Groups[1].Value

        $Replacestring = $InputResponse.Where{ $_.Name -eq $ReplaceKey }[0].Val
        
        $InputData = $InputData -replace [RegEx]::Escape($SearchString), $Replacestring
    }

    Return $InputData
    
}
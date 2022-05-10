Function Literalize {

    [CmdLetBinding()]
    Param(
        [Array]$InputResponse,
        [String]$InputData
    )

    $VariableList = [Regex]::New("(?msi)\[\[(\w{1,})\]\]").Matches($InputData)

    ForEach($V in $VariableList) {        
        $SearchString = $V.Groups[0].Value
        $ReplaceKey = $V.Groups[1].Value

        $ReplaceString = $InputResponse.Where{ $_.Name -eq $ReplaceKey }[0].Val
        
        $InputData = $InputData -replace [RegEx]::Escape($SearchString), $Replacestring
    }

    Return $InputData
    
}
Function Get-AnswersToInputQuestions {

    [CmdLetBinding()]
    Param(
        [Array]$InputData
    )

    $InputResponse = ForEach($P in $InputData) {

        Do {

            Try {
                       
                Write-Verbose "   Prompting for '$($P.Prompt)'"
                
                If($P.Secure -eq $True) {
                    $SecureVal = Read-Host "$($P.Prompt)" -AsSecureString
                    $Val = [System.Net.NetworkCredential]::new("", $SecureVal).Password
                } else {
                    $Val = Read-Host "$($P.Prompt)"

                    $ValueNoError = $True            
 
                    If($Val -notmatch $P.ValidateRegEx) {
                        Write-Warning "Response failed validation. $($P.ValidateMesssage)"
                        $ValueNoError = $False
                    }

                }
            } Catch {
                Write-Warning $_.Exception.Message
                $ValueNoError = $False
            }
        
        } Until ($ValueNoError)

        [PSCustomObject]@{
            "Name" = $P.Name
            "Val" = $Val
            "Secure" = $P.Secure
        }

    }

    Return $InputResponse

}
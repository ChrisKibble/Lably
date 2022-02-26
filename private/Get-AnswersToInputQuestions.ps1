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
                    Do {
                        $SecureVal = Read-Host "$($P.Prompt)" -AsSecureString
                        $Val = [System.Net.NetworkCredential]::new("", $SecureVal).Password   
                        Write-Host "[Confirmation] " -ForegroundColor Yellow -NoNewLine
                        $SecureValConfirm = Read-Host "$($P.Prompt)" -AsSecureString
                        $ValConfirm = [System.Net.NetworkCredential]::new("", $SecureValConfirm).Password
                        If(-Not($Val -ceq $ValConfirm)) {
                            Write-Host "Passwords do not match. Try again." -ForegroundColor Red
                        }
                    } Until($Val -ceq $ValConfirm)
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
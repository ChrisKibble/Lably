Function Get-AnswersToInputQuestions {

    [CmdLetBinding()]
    Param(
        [Array]$InputQuestions,
        [String]$OSLanguage = $(Get-WinSystemLocale -ErrorAction SilentlyContinue).Name
    )

    $InputData = $InputQuestions[0].PSObject.Properties | ForEach-Object {
        
        $PromptName = $_.Name

        Write-Verbose "Processing $PromptName Prompt"
        $ThisInput = $InputQuestions.$PromptName
        
        $PromptList = $ThisInput.Prompt
        $ValidateList = $ThisInput.Validate
        $ValidateRegEx = $ThisInput.Validate.RegEx
        $AskWhen = $ThisInput.AskWhen
        $Secure = $ThisInput.Secure

        If($OSLanguage -and $PromptList.$OSLanguage) {
            Write-Verbose "   Prompt Language Matched OS Language"
            $PromptLanguage = $OSLanguage
        } else {
            Write-Verbose "   Prompt Language did not match OS Langauge, picking from list."
            $PromptLanguage = $PromptList | Select-Object -First 1 | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        }

        $PromptValue = $PromptList.$PromptLanguage

        If($ValidateList) {
            If($OSLanguage -and $ValidateList.Message.$OSLanguage) {
                Write-Verbose "   Validation Language Matched OS Language"
                $ValidateLanguage = $OSLanguage
            } else {
                Write-Verbose "   Validation Language did not match OS Langauge, picking from list."
                $ValidateLanguage = $ValidateList.Message | Select-Object -First 1 | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            }    

            $ValidateValue = $ValidateList.Message.$ValidateLanguage
        } else {
            $ValidateValue = $null
        }

        [PSCustomObject]@{
            "Name" = $PromptName
            "ValidateRegEx" = $ValidateRegEx
            "Prompt" = $PromptValue
            "ValidateMesssage" = $ValidateValue
            "AskWhen" = $AskWhen
            "Secure" = [Boolean]$Secure
        }
    }
    
    $InputResponse = @()

    $QNumber = 0
    ForEach($P in $InputData) {

        If($P.AskWhen) {
            $AskWhen = Literalize -InputResponse $InputResponse -InputData $P.AskWhen
            $Continue = Invoke-Expression $AskWhen

            If(-Not($Continue)) { Continue }
        }

        $QNumber++

        Do {

            Try {
                       
                Write-Verbose "   Prompting for '$($P.Prompt)'"
                
                Write-Host "($QNumber) " -ForegroundColor Yellow -NoNewline
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
                        Write-Host ""
                    } Until($Val -ceq $ValConfirm)
                } else {
                    $Val = Read-Host "$($P.Prompt)"

                    $ValueNoError = $True
 
                    If($Val -notmatch $P.ValidateRegEx) {
                        Write-Warning "Response failed validation. $($P.ValidateMesssage)"
                        Write-Host ""
                        $ValueNoError = $False
                    }

                }
            } Catch {
                Write-Warning $_.Exception.Message
                $ValueNoError = $False
            }
        
        } Until ($ValueNoError)

        $InputResponse += [PSCustomObject]@{
            "Name" = $P.Name
            "Val" = $Val
            "Secure" = $P.Secure
        }

    }

    Write-Host ""
    Return $InputResponse

}
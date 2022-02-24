Function Import-Lably {

    [CmdLetBinding()]
    Param(
        [String]$Path,
        [String]$Template
    )

    $LablyScaffold = Join-Path $Path -ChildPath "scaffold.lably.json"
    Write-Verbose "Reading Lably Scaffolding File at $LablyScaffold"

    If(-Not(Test-Path $LablyScaffold -ErrorAction SilentlyContinue)){
        Throw "There is no Lably at $Path."
    }

    Try {
        $Scaffold = Get-Content $LablyScaffold | ConvertFrom-Json
    } Catch {
        Throw "Unable to import Lably scaffold. $($_.Exception.Message)"
    }

    Try {
        $BaseVHDRegistryFile = "$env:UserProfile\Lably\BaseImageRegistry.json"
        Write-Verbose "Reading BaseVHDs from $BaseVHDRegistryFile"
        $BaseVHDRegistry = $(Get-Content $BaseVHDRegistryFile -ErrorAction Stop | ConvertFrom-Json).BaseImages | Sort-Object { [Version]$_.OSVersion, [DateTime]$_.DateAdded } -Descending
    } Catch {
        Throw "Unable to read Base VHD Registry File at $BaseVHDRegistryFile. $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Getting Language of Operating System"
        $OSLanguage = $(Get-WinSystemLocale -ErrorAction Stop).Name
    } Catch {
        Write-Warning "Unable to find Operating System Langauge"
        $OSLanguage = $null
    }

    Try {
        Write-Verbose "Reading Template"
        $ThisTemplate = Get-Content $Template -Raw | ConvertFrom-Json
    } catch {
        Throw "Unable to read template file. $($_.Exception.Message)"
    }


    Write-Verbose "Processing List of Assets Required"
    $Assets = $ThisTemplate.Assets | Get-Member -MemberType NoteProperty | ForEach-Object { 
        
        $AssetId = $_.Name
        Write-Verbose "   Building '$AssetId'"
        
        $OS = @($ThisTemplate.Assets.$AssetId.OSVHD.OS)
        $OSVersion = @($ThisTemplate.Assets.$AssetId.OSVHD.OSVersion)
        
        If($ThisTemplate.Assets.$AssetId.OSVHD.OSEdition) {
            $OSEdition = @($ThisTemplate.Assets.$AssetId.OSVHD.OSEdition)
        } else {
            $OSEdition = @("*")
        }
        
        $VHDMatch = $null

        ## TODO: Allow user to define GUID to use when calling this function instead of auto-detecting.

        ForEach($OSV in $OSVersion) {
            ForEach($OSE in $OSEdition) {
                Write-Verbose "   Searching Registry for OS '$OSV' with '$OSE' within OS = '$OS'"
                $VHDMatch = @($BaseVHDRegistry).Where({ $_.OSName -eq $OS -and $_.OSVersion -like $OSV -and $_.OSEdition -like $OSE },'first')
                If($VHDMatch) {
                    break
                }
            }
            If($VHDMatch) { break }
        }

        Write-Verbose "BaseVHD Search Complete"

        If(-Not($VHDMatch)) {
            Write-Warning "Unable to find base image to match requirements for '$AssetId'"
            Write-Warning "   OS='$OS'"
            Write-Warning "   OS Version like $($OSVersion -join " or ")"
            Write-Warning "   OS Edition like $($OSEdition -join " or ")"
            Throw "No valid base image available for $AssetId"
        }

        Write-Verbose "Using BaseVHD $($VHDMatch.ImagePath)"

        [PSCustomObject]@{
            VMHostName = $ThisTemplate.Assets.$AssetId.VMName
            BaseVHD = $VHDMatch.ImagePath
            PostBuild = $ThisTemplate.Assets.$AssetId.PostBuild
            AdminPassword = $ThisTemplate.Assets.$AssetId.AdminPassword
        }
    }  

    Write-Verbose "Reading Input Prompts from Template"

    ## TODO: Some kind of answer file option for this.
    $InputData = $ThisTemplate.Input | Get-Member -MemberType NoteProperty | ForEach-Object {
        
        $PromptName = $_.Name

        Write-Verbose "Processing $PromptName Prompt"
        $ThisInput = $ThisTemplate.Input.$PromptName
        
        $Index = $ThisInput.Index
        $PromptList = $ThisInput.Prompt
        $ValidateList = $ThisInput.Validate
        $ValidateRegEx = $ThisInput.Validate.RegEx
        $Secure = $ThisInput.Secure

        If($OSLanguage -and $PromptList.$OSLanguage) {
            Write-Verbose "   Prompt Language Matched OS Language"
            $PromptLanguage = $OSLanguage
        } else {
            ## TODO: Allow user to set default language outside of the OS
            Write-Verbose "   Prompt Language did not match OS Langauge, picking from list."
            $PromptLanguage = $PromptList | Select-Object -First 1 | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        }

        $PromptValue = $PromptList.$PromptLanguage

        If($ValidateList) {
            If($OSLanguage -and $ValidateList.Message.$OSLanguage) {
                Write-Verbose "   Validation Language Matched OS Language"
                $ValidateLanguage = $OSLanguage
            } else {
                ## TODO: Allow user to set default language outside of the OS
                Write-Verbose "   Validation Language did not match OS Langauge, picking from list."
                $ValidateLanguage = $ValidateList.Message | Select-Object -First 1 | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            }    

            $ValidateValue = $ValidateList.Message.$ValidateLanguage
        } else {
            $ValidateValue = $null
        }

        [PSCustomObject]@{
            "Index" = $Index
            "Name" = $PromptName
            "ValidateRegEx" = $ValidateRegEx
            "Prompt" = $PromptValue
            "ValidateMesssage" = $ValidateValue
            "Secure" = [Boolean]$Secure
        }
    } | Sort-Object Index

    $InputResponse = Get-AnswersToInputQuestions -InputData $InputData

    ForEach($Asset in $Assets) {

        $VMHostName = Literalize -InputResponse $InputResponse -InputData $Asset.VMHostName
        $VMPassword = Literalize -InputResponse $InputResponse -InputData $Asset.AdminPassword

        $VMPassword = $VMPassword | ConvertTo-SecureString -AsPlainText -Force

        Try {
            Write-Host "Building $VMHostName"
            $VM = New-LablyVM -Path $Path -DisplayName $VMHostName -Hostname $VMHostName -BaseVHD $Asset.BaseVHD -AdminPassword $VMPassword
            Get-VM -Id $VM.VMid | Start-VM
            # Sleep to let the system start.
            Start-Sleep -Seconds 5
        } Catch {
            Throw "Could not create or start new virtual machine. $($_.Exception.Message)"
        }

        Try {
            [PSCredential]$Administrator = New-Object System.Management.Automation.PSCredential("Administrator", $VMPassword)
        } Catch {
            Throw "Could not create credential object to connect to new virtual machine."
        }

        $WaitStart = Get-Date

        Do {
            $TSLength = New-TimeSpan -Start $WaitStart -End (Get-Date)
            Try {
                Invoke-Command -VMId $VM.VMid -ScriptBlock { Write-Host ">>> Hello, this is $($env:username) calling out from $($env:computername). I'm online!" } -Credential $Administrator -ErrorAction Stop | Out-Null
                $Connected = $True
            } Catch {
                Write-Host "... Virtual Machine not yet reachable. Retrying."
                $Connected = $False
                Start-Sleep -Seconds 5
            }
        } Until ($Connected -or $TSLength.Minutes -ge 5)
        
        If(-Not $Connected) {
            Throw "Timeout while attempting to configure new virtual machine."
        }

        ForEach($Step in $Asset.PostBuild | Sort-Object Index) {

            Switch($Step.Action) {
                'Script' {
                    
                    Switch($Step.Language) {
                        'PowerShell' {
                            Write-Verbose "Running Script Against VM"
                            $authUser = Literalize -InputResponse $InputResponse -InputData $Step.auth.User
                            $authPass = Literalize -InputResponse $InputResponse -InputData $Step.auth.Pass | ConvertTo-SecureString -AsPlainText -Force

                            [PSCredential]$ScriptUser = New-Object System.Management.Automation.PSCredential($authUser, $authPass)
                                                       
                            $StepScript = $Step.Script -join "`n"
                            $StepScript = Literalize -InputResponse $InputResponse -InputData $($StepScript)
                            Write-Host "Running:"
                            Write-Host $StepScript
                            $stepScriptBlock = [ScriptBlock]::Create($StepScript)

                            Try {
                                Invoke-Command -VMId $VM.VMid -ScriptBlock $stepScriptBlock -Credential $ScriptUser
                            } Catch {
                                Write-Warning "Unable to run Step #$($Step.Index) - $($_.Exception.Message)"
                            }
                        }
                        default {
                            Write-Warning "Unknown Script Language '$($Step.Language)'"
                        }
                    }
                }
                default {
                    Write-Warning "Unknown post build directive '$($Step.Action)'"
                }
            }
            
        }

    }

}

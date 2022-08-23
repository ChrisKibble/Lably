Function New-LablyVM {
    
    <#
    
    .SYNOPSIS

    Creates a new VM in Hyper-V using a Base VHD.

    .DESCRIPTION

    This function is used to create a new Hyper-V VM that will use a differencing disk based on a registered Base VHD.

    .PARAMETER Path
    
    Optional parameter to define where the lably that this VM will join is stored. If this parameter is not defined, it will default to the path from which the function was called.

    .PARAMETER Template

    Optional template to be used. Templates will be loaded from the "Templates" subfolder of the module and custom ones can be installed into the Lably\Templates folder of the user profile. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .PARAMETER DisplayName

    Optional DisplayName to be used in Hyper-V. Defaults to the hostname of the VM prefixed by the name of the Lably (e.g., [Chris' Lab] LABDC01).

    .PARAMETER Hostname

    Optional Hostname for the VM. Defaults to 'LAB-' followed by a random string of 8 random alphanumeric characters. Some templates may require that a hostname be defined.

    .PARAMETER BaseVHD

    The path or friendly name of the BaseVHD that should be used to create this VM. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .PARAMETER AdminPassword

    SecureString input of the AdminPassword that should be used to login to the VM. This parameter will not take plain text, see examples for assistance creating secure strings.

    .PARAMETER MemorySizeInBytes

    Optional Memory that should be assigned to the VM. Defaults to 4GB. Although this parameter takes the value in bytes, PowerShell will calculate this value for you if you use MB or GB in after a value (e.g. 512MB or 2GB).

    .PARAMETER MemoryMinimumInBytes

    Optional Minimum Memory that should be assigned to the VM. Defaults to 512MB. Although this parameter takes the value in bytes, PowerShell will calculate this value for you if you use MB or GB in after a value (e.g. 512MB or 2GB).

    .PARAMETER MemoryMaximumInBytes

    Optional Maximum Memory that should be assigned to the VM. Defaults to the same value supplied to MemorySizeInBytes. Although this parameter takes the value in bytes, PowerShell will calculate this value for you if you use MB or GB in after a value (e.g. 512MB or 2GB).

    .PARAMETER CPUCount

    Optional number of virtual CPUs to assign to the VM. Defaults to 1/4th of the total number of logical processors that the host has.

    .PARAMETER ProductKey

    Optional product key that should be used when building the VM. The product key is typically stored in the Base VHD, so this parameter is only necessary if you didn't include one in the Base VHD or if you'd like to use a different one for this VM.

    .PARAMETER TimeZone

    Optional TimeZone ID to use when building this VM. Defaults to the timezone of the host.

    .PARAMETER Locale

    Optional Windows Locale ID to use when building this VM. Defaults to the Locale ID of the host.

    .PARAMETER Force

    Switch that defines that the VHD should be overwritten if it already exists.

    .INPUTS

    None. You cannot pipe objects to New-LablyVM.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    New-LablyVM -BaseVHD C:\BaseVHDs\Windows10-Ent.vhdx -AdminPassword $("S3cur3P@s5w0rd" | ConvertTo-SecureString -AsPlainText -Force)

    .EXAMPLE

    New-LablyVM -BaseVHD C:\BaseVHDs\WindowsServer2022.vhdx -Template "Windows Active Directory Forest" -Hostname LABDC01 -MemorySizeInBytes 4GB -MemoryMinimumInBytes 512MB -MemoryMaximumInBytes 4GB -CPUCount 2

    .EXAMPLE

    $AdminPassword = "MySuperPassword###1" | ConvertTo-SecureString -AsPlainText -Force
    New-LablyVM -BaseVHD C:\BaseVHDs\Windows10-Ent.vhdx -MemorySizeInBytes 4GB -Timezone "Eastern Standard Time" -Locale "en-us" -AdminPassword $AdminPassword

    #>

    [CmdLetBinding(DefaultParameterSetName='TemplateAnswers')]
    Param(

        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD,

        [Parameter(Mandatory=$False)]
        [String]$Template,

        [Parameter(Mandatory=$False,ParameterSetName="TemplateAnswers")]
        [HashTable]$TemplateAnswers = @{},

        [Parameter(Mandatory=$False,ParameterSetName="TemplateAnswerFile")]
        [String]$TemplateAnswerFile = "",

        [Parameter(Mandatory=$False)]
        [String]$DisplayName,

        [Parameter(Mandatory=$False)]
        [String]$Hostname = "LAB-$([Guid]::NewGuid().ToString().split('-')[0].ToUpper())",

        [Parameter(Mandatory=$True)]
        [String]$BaseVHD,

        [Parameter(Mandatory=$True)]
        [SecureString]$AdminPassword,

        [Parameter(Mandatory=$False)]
        [Int64]$MemorySizeInBytes = 4GB,

        [Parameter(Mandatory=$False)]
        [Int64]$MemoryMinimumInBytes = 512MB,

        [Parameter(Mandatory=$False)]
        [Int64]$MemoryMaximumInBytes = $MemorySizeInBytes,

        [Parameter(Mandatory=$False)]
        [Int]$CPUCount = [Math]::Max(1,$(Get-CimInstance -Class Win32_Processor).NumberOfLogicalProcessors/4),

        [Parameter(Mandatory=$False)]
        [String]$ProductKey,

        [Parameter(Mandatory=$False)]
        [String]$Timezone = $(Get-Timezone).Id,

        [Parameter(Mandatory=$False)]
        [String]$Locale = $(Get-WinSystemLocale).Name,

        [Parameter(Mandatory=$False)]
        [Switch]$Force
    )

    ValidateModuleRun -RequiresAdministrator

    $VMGUID = [GUID]::NewGuid().Guid

    $LablyScaffold = Join-Path $Path -ChildPath "scaffold.lably.json"
    $Scaffold = Import-LablyScaffold -LablyScaffold $LablyScaffold -ErrorAction Stop

    If(-Not(Get-VMSwitch -Id $Scaffold.Meta.SwitchId -ErrorAction SilentlyContinue)) {
        Throw "Switch in Lably Scaffold does not exist."
    }

    Try {
        $SwitchName = $(Get-VMSwitch -Id $Scaffold.Meta.SwitchId | Select-Object -First 1).Name
    } Catch {
        Throw "Unable to get name of switch $Scaffold.Meta.SwitchId."
    }

    If(-Not($DisplayName)) {
        $DisplayName = $Hostname
    }

    If($DisplayName -notmatch "\[$($Scaffold.Meta.Name)\] .*") {
        $DisplayName = "[$($Scaffold.Meta.Name)] $DisplayName"
    }

    If(Get-VM | Where-Object { $_.Name -eq $DisplayName }) {
        Throw "VM '$DisplayName' already exists."
    }

    If(-Not($Scaffold.Meta.VirtualDiskPath)) {
        Throw "No Virtual Disk Path defined in Lably Scaffold."
    }

    Try {
        $BaseImageRegistry = Get-Content $env:UserProfile\Lably\BaseImageRegistry.json -Raw | ConvertFrom-Json
    } Catch {
        Throw "Unable to read Base Image Registry. $($_.Exception.Message)"
    }
    
    $RegistryEntry = $BaseImageRegistry.BaseImages.Where{($_.ImagePath -eq $BaseVHD -or $_.FriendlyName -eq $BaseVHD -or $_.Id -eq $BaseVHD)}[0]

    If(-Not($RegistryEntry)) {
        Throw "Cannot Find Base VHD."
    }

    $BaseVHD = $RegistryEntry.ImagePath

    If(-Not(Test-Path $BaseVHD -ErrorAction SilentlyContinue)) {
        Throw "Cannot find $BaseVHD"
    }

    If($Template) {

        If($Template -like "`"*`"") {
            # Remove Quotes
            $Template = $Template.Substring(1,$Template.Length-1)
        }
        
        # User Template over Module Template - Look at User Templates First
        $UserTemplateFile = Join-Path $env:UserProfile -ChildPath "Lably\Templates\$Template.json"
        $ModuleTemplateFolder = Join-Path (Split-Path $PSScriptRoot) -ChildPath "Templates"
        $ModuleTemplateFile = Join-Path $ModuleTemplateFolder -ChildPath "$Template.json"

        If(Test-Path $Template) {
            $TemplateFile = $Template
        } ElseIf(Test-Path $UserTemplateFile) {
            $TemplateFile = $UserTemplateFile
        } ElseIf(Test-Path $ModuleTemplateFile) {
            $TemplateFile = $ModuleTemplateFile
        } else {
            Throw "Cannot find $Template"
        }

        $LablyTemplate = Get-LablyTemplate $TemplateFile

        Write-Host ""
        Write-Host "Building: $($LablyTemplate.Meta.Name) v$($LablyTemplate.Meta.Version) by $($LablyTemplate.Meta.Author)." -ForegroundColor DarkGreen
        If($Scaffold.Meta.NATIPCIDR) {
            Write-Host "Lab IP Range: $($Scaffold.Meta.NATIPCIDR)" -ForegroundColor DarkGreen
        }
        Write-Host ""

        $HostnameDefined = If($PSBoundParameters.ContainsKey("Hostname")) { $True } Else { $False }

        If(-Not(ValidateTemplate2BaseVHD -LablyTemplate $LablyTemplate -RegistryEntry $RegistryEntry -HostnameDefined $HostnameDefined)) {
            Throw "One or more of the requirements of this template were not met. Read the above warning messages for more information."
        }

        If($TemplateAnswerFile) {
            Try {
                $AnswerData = Get-Content $TemplateAnswerFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            } Catch {
                Throw "Could not read Template Answer File. $($_.Exception.Message)"
            }

            $TemplateAnswers = @{}
            ForEach($AnswerProperty in $AnswerData.PSObject.Properties) {
                $TemplateAnswers.Add($AnswerProperty.Name,$AnswerProperty.value)
            }

        }

        $InputResponse = Get-AnswersToInputQuestions -InputQuestions $LablyTemplate.Input -TemplateAnswers $TemplateAnswers

    }

    If(-Not(Test-Path $Scaffold.Meta.VirtualDiskPath)) {
        Try {
            New-Item -ItemType Directory -Path $Scaffold.Meta.VirtualDiskPath -ErrorAction Stop | Out-Null
        } Catch {
            Throw "Cannot create $($Scaffold.Meta.VirtualDiskPath). $($_.Exception.Message)"
        }
    
    }

    $OSVHDPath = Join-Path $Scaffold.Meta.VirtualDiskPath -ChildPath "OSDisk.vhdx"

    If($(Test-Path $OSVHDPath) -and $Force) {
        Try {
            Remove-Item $OSVHDPath -Force -ErrorAction Stop
        } Catch {
            Throw "Could not remove $OSVHDPath. $($_.Exception.Message)"
        }
    }

    If(-Not($ProductKey)) {
        $ProductKey = $RegistryEntry.ProductKey
    }

    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
    Write-Host "Creating New VHD for VM." -NoNewline

    Try {
        $VHD = New-VHD -Differencing -Path $OSVHDPath -ParentPath $BaseVHD -ErrorAction Stop
        Write-Host " Success." -ForegroundColor Green
    } Catch {
        Write-Host " Failed." -ForegroundColor Red
        Throw "Cannot create $OSVHDPath. $($_.Exception.Message)"
    }    

    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
    Write-Host "Mounting Operating System VHD." -NoNewline

    Try {
        $vhdMount = Mount-VHD -Path $VHD.Path -Passthru -ErrorAction Stop
        Write-Host " Success." -ForegroundColor Green
    } Catch {
        Write-Host " Failed." -ForegroundColor Red
        Remove-Item $VHD.Path -ErrorAction SilentlyContinue
        Throw "Could not mount $($VHD.Path). $($_.Exception.Message)"
    }

    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
    Write-Host "Getting Local Disk Information from VHD." -NoNewline

    Try {
        $VHDDriveLetter = $(Get-Partition -DiskNumber $VHDMount.DiskNumber | Where-Object { $_.Type -eq "Basic" -and $_.DriveLetter })[0].DriveLetter
        [String]$VHDDriveLetter += ":"
        Write-Host " Success." -ForegroundColor Green
    } Catch {
        Write-Host " Failed." -ForegroundColor Red
        Dismount-Vhd -Path $VHD.Path -ErrorAction SilentlyContinue
        Remove-Item $VHD.Path -ErrorAction SilentlyContinue
        Throw "Could not get drive letter from $($VHD.Path). $($_.Exception.Message)"
    }

    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
    Write-Host "Creating Unattended Install for Guest Operating System." -NoNewline

    Try {
        $unattendPath = Join-Path $VHDDriveLetter -ChildPath "Windows\Panther"
        If(-Not(Test-Path $unattendPath)) {
            New-Item -ItemType Directory -Path $unattendPath -ErrorAction Stop | Out-Null
        }
        
        $unattendFile = Join-Path $unattendPath -ChildPath "unattend.xml"

        $xmlArgs = @{
            ComputerName = $Hostname
            Timezone = $Timezone
            AdminPassword = $AdminPassword
            Locale = $Locale
        }
        
        If($ProductKey) {
            $xmlArgs.Add('ProductKey', $ProductKey)
        }

        $xmlUnattend = Update-Unattend @xmlArgs

        $xmlUnattend.Save($unattendFile)

        Write-Host " Success." -ForegroundColor Green
        
    } Catch {
        Write-Host " Failed." -ForegroundColor Red
        Dismount-Vhd -Path $VHD.Path -ErrorAction SilentlyContinue
        Remove-Item $VHD.Path -ErrorAction SilentlyContinue
        Throw "Could not setup Unattend on VHD. $($_.Exception.Message)"
    }

    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
    Write-Host "Dismounting VHD and passing control to Hyper-V." -NoNewline

    Try {
        Dismount-Vhd -Path $VHD.Path -ErrorAction Stop
        Write-Host " Success." -ForegroundColor Green
    } Catch {
        Write-Host " Warning!" -ForegroundColor Yellow
        Write-Warning "Could not dismount $($VHD.Path), you'll need to manually dismount or reboot before using. $($_.Exception.Message)"
    }

    Write-Host "[Hyper-V] " -ForegroundColor Magenta -NoNewline
    Write-Host "Setting up VM in Hyper-V." -NoNewline

    Try {
        $NewVM = New-VM -Name $DisplayName -MemoryStartupBytes $MemorySizeInBytes -VHDPath $VHD.Path -Generation 2 -SwitchName $SwitchName -ErrorAction Stop
        Write-Host " Success." -ForegroundColor Green
    } Catch {
        Write-Host " Failed." -ForegroundColor Red
        Remove-Item $VHD.Path -ErrorAction SilentlyContinue
        Throw "Could not create $DisplayName. $($_.Exception.Message)"
    }

    Write-Host "[Hyper-V] " -ForegroundColor Magenta -NoNewline
    Write-Host "Configuring VM Memory with Min=$([Math]::Round($MemoryMinimumInBytes/1GB,2))GB, Max=$([Math]::Round($MemoryMaximumInBytes/1GB,2))GB, Startup=$([Math]::Round($MemorySizeInBytes/1GB,2))GB." -NoNewline

    Try {
        Set-VMMemory -VM $NewVM -MinimumBytes $MemoryMinimumInBytes -MaximumBytes $MemoryMaximumInBytes -ErrorAction Stop
        Write-Host " Success." -ForegroundColor Green
    } Catch {
        Write-Host " Warning!" -ForegroundColor Yellow
        Write-Warning "Unable to change VM CPU Settings. $($_.Exception.Message)"        
    }

    Write-Host "[Hyper-V] " -ForegroundColor Magenta -NoNewline
    Write-Host "Configuring VM with $CPUCount Virtual CPUs." -NoNewline

    Try {
        Set-VMProcessor -VM $NewVM -Count $CPUCount -ErrorAction Stop
        Write-Host " Success." -ForegroundColor Green
    } Catch {
        Write-Host " Warning!" -ForegroundColor Yellow
        Write-Warning "Unable to change VM CPU Settings. $($_.Exception.Message)"        
    }

    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
    Write-Host "Updating Lably Scaffold." -NoNewline

    Try {
        $Scaffold = Get-Content $LablyScaffold | ConvertFrom-Json
        
        If(-Not($Scaffold.Assets)) {
            Add-Member -InputObject $Scaffold -MemberType NoteProperty -Name Assets -Value @() -ErrorAction SilentlyContinue
        }
        
        $SecureAdminPassword = Get-DecryptedString -EncryptedText $AdminPassword 
        $SecureAdminPassword = Get-EncryptedString -PlainText $SecureAdminPassword -SecretType $Scaffold.Secrets.SecretType -SecretKeyFile $Scaffold.secrets.KeyFile

        $ThisAsset = [PSCustomObject]@{
            DisplayName = $DisplayName
            Hostname = $Hostname
            CreatedUTC = $(Get-DateUTC)
            TemplateGuid = $LablyTemplate.Meta.Id
            BaseVHD = $RegistryEntry.Id
            VMId = $NewVM.VMId
            AdminPassword = $SecureAdminPassword
            ProductKey = $ProductKey
            Timezone = $Timezone
            Locale = $Locale
            Hardware = @{
                MemorySizeInBytes = $MemorySizeInBytes
                MemoryMinimumInBytes = $MemoryMinimumInBytes
                MemoryMaximumInBytes = $MemoryMaximumInBytes
                CPUCount = $CPUCount
            }
        }

        If($InputResponse) {
            
            $ScaffoldResponse = $InputResponse | ConvertTo-Json -Depth 100 | ConvertFrom-Json

            ForEach($SecureProperty in $ScaffoldResponse | Where-Object { $_.Secure -eq $True }) {
                $SecureProperty.Val = Get-EncryptedString -PlainText $SecureProperty.Val -SecretType $Scaffold.Secrets.SecretType -SecretKeyFile $Scaffold.Secrets.KeyFile
            }

            Add-Member -InputObject $ThisAsset -MemberType NoteProperty -Name InputResponse -Value $ScaffoldResponse.PSObject.BaseObject
        }
        
        [Array]$Scaffold.Assets += @($ThisAsset)

        $Scaffold | ConvertTo-Json -Depth 10 | Out-File $LablyScaffold -Force
        Write-Host " Success." -ForegroundColor Green
    } Catch {
        Write-Host " Warning!" -ForegroundColor Yellow
        Write-Warning "VM is online but we were unable to add it to your Lably Scaffold."
        Write-Warning $_.Exception.Message
    }

    If($Template) {
        $TemplatePath = Join-Path $Path -ChildPath "Template Cache"
        $TemplateCacheFile = Join-Path $TemplatePath -ChildPath "$($LablyTemplate.Meta.Id).json"
        If($TemplateFile -ne $TemplateCacheFile) {
            Try {
                Copy-Item -Path $TemplateFile -Destination $TemplateCacheFile -Force -ErrorAction Stop
            } Catch {
                Write-Warning "Unable to cache template. $($_.Exception.Message)"
            }
        }
    }

    If(-Not($Template)) {
        Write-Host "Awesome! Your new Virtual Machine is ready to use." -ForegroundColor Green
        Return $NewVM
    }

    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
    Write-Host "VM Creation Complete. Starting VM to Apply Template." -ForegroundColor Green
    Write-Host ""

    Try {
        $NewVM | Start-VM -ErrorAction Stop
    } Catch {
        Throw "Could not start VM. $($_.Exception.Message)"
    }

    Try {
        [PSCredential]$BuildAdministrator = New-Object System.Management.Automation.PSCredential("$Hostname\Administrator", $AdminPassword)
    } Catch {
        Throw "Could not create credential object to connect to new virtual machine."
    }

    $WaitStart = Get-Date

    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
    Write-Host "Waiting for VM to be Operational. Will test every 10 seconds up to 5 minutes."

    Do {
        $TSLength = New-TimeSpan -Start $WaitStart -End (Get-Date)
        Try {
            Invoke-Command -VMId $NewVM.VMid -ScriptBlock { 
                Write-Host "[VM:$($env:computername)] " -ForegroundColor Magenta -NoNewline
                Write-Host "Hello, this is $($env:username) calling out from $($env:computername). I'm online!" 
            } -Credential $BuildAdministrator -ErrorAction Stop | Out-Null
            $Connected = $True
        } Catch {
            $Connected = $False
            Start-Sleep -Seconds 10
        }
    } Until ($Connected -or $TSLength.Minutes -ge 5)
    
    If(-Not $Connected) {
        Throw "Timeout while attempting to configure new virtual machine."
    }
    
    Try {
        Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
        Write-Host "Waiting for VM Network to be Available. Will try every 15 seconds."
        Invoke-Command -VMId $NewVM.VMId -ScriptBlock {
            While (Get-NetConnectionProfile | Where-Object { $_.Name -eq "Identifying..." }) {
                Start-Sleep -Seconds 15
            }
            Write-Host "[VM] " -ForegroundColor Magenta -NoNewline
            Write-Host "Setting Network Type of Private and Enabling PSRemoting (You can change this later if desired)." -NoNewLine
            Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction Stop
            Enable-PSRemoting -Force -ErrorAction Stop | Out-Null 
        } -Credential $BuildAdministrator -ErrorAction Stop
        Write-Host " Success!" -ForegroundColor Green
    } Catch {
        Throw $_.Exception.Message
    }

    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
    Write-Host "Starting Post Build Steps from Template"

    ForEach($Step in $LablyTemplate.Asset.PostBuild) {

        If($Step.RunWhen) {
            $RunWhen = Literalize -InputResponse $InputResponse -InputData $Step.RunWhen
            $Continue = Invoke-Expression $RunWhen
            If(-Not($Continue)) { 
                Continue
            }
        }

        Write-Host "[VM] " -ForegroundColor Magenta -NoNewline
        Write-Host "Executing Step '$($Step.Name)' - " -NoNewline

        Try {
            
            If($Step.Credential.Username) {
                $StepAdminName = Literalize -InputResponse $InputResponse -InputData $Step.Credential.Username
            } Else {
                $StepAdminName = $BuildAdministrator.Username
            }

            If($Step.ValidationCredential.Username) {
                $ValidationAdminName = Literalize -InputResponse $InputResponse -InputData $Step.ValidationCredential.Username
            } else {
                $ValidationAdminName = $BuildAdministrator.Username
            }

            [PSCredential]$StepAdministrator = New-Object System.Management.Automation.PSCredential($StepAdminName, $AdminPassword)
            [PSCredential]$ValidationAdministrator = New-Object System.Management.Automation.PSCredential($ValidationAdminName, $AdminPassword)

        } Catch {
            Throw "Could not create credential object to connect to new virtual machine."
        }

        Switch($Step.Action) {
            'Script' {

                If($Step | Get-Member ExpandVariables -ErrorAction SilentlyContinue) {
                    $ExpandVariables = $Step.ExpandVariables
                } Else {
                    $ExpandVariables = $true
                }
        
                Switch($Step.Language) {
                    'PowerShell' {
                        Write-Host "Running PowerShell Script on VM as $($StepAdministrator.UserName)"

                        $StepScript = $Step.Script -join "`n"
                        If($ExpandVariables) {
                            $StepScript = Literalize -InputResponse $InputResponse -InputData $($StepScript)
                        }
                        $stepScriptBlock = [ScriptBlock]::Create($StepScript)

                        Try {
                            Invoke-Command -VMId $NewVM.VMId -ScriptBlock $stepScriptBlock -Credential $StepAdministrator
                        } Catch {
                            Write-Warning "Unable to run Step - $($_.Exception.Message)"
                        }
                    }
                    default {
                        Write-Warning "Unknown Script Language '$($Step.Language)'"
                    }
                }
            }
            'Reboot' {
                Try {
                    Write-Host "Rebooting Computer as $($StepAdministrator.Username)"
                    Invoke-Command -VMId $NewVM.VMId -ScriptBlock { Restart-Computer -Force } -Credential $StepAdministrator
                    Start-Sleep -Seconds 30
                } Catch {
                    Write-Warning "Unable to run Step - $($_.Exception.Message)"
                }
 
                Do {

                    $WaitStart = Get-Date
                    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewline
                    Write-Host "Waiting for VM to be Operational. Will test every 10 seconds up to 5 minutes."
                
                    Do {
                        $TSLength = New-TimeSpan -Start $WaitStart -End (Get-Date)
                        Try {
                            Invoke-Command -VMId $NewVM.VMid -ScriptBlock { 
                                Write-Host "[VM:$($env:computername)] " -ForegroundColor Magenta -NoNewline
                                Write-Host "Hello, this is $($env:username) calling out from $($env:computername). I'm online!" 
                            } -Credential $ValidationAdministrator -ErrorAction Stop | Out-Null
                            $Connected = $True
                        } Catch {
                            $Connected = $False
                            Start-Sleep -Seconds 10
                        }
                    } Until ($Connected -or $TSLength.Minutes -ge 5)

                    If(-Not($Connected)) {
                        Do {
                            $PromptContinue = Read-Host "It's taking a while to reconnect. Do you want to keep trying (Y/N)?"
                        } Until ($PromptContinue -in @("Y","N"))
                        If($PromptContinue -ne "Y") {
                            Throw "Timeout waiting for VM to come back online."
                        }
                    }

                } Until($Connected)

            }
            default {
                Write-Warning "Unknown post build directive '$($Step.Action)'"
            }
        }
        
    }
 
    Write-Host "[Lably] " -ForegroundColor Magenta -NoNewLine
    Write-Host "Completed Running Post-Build Steps"

    Write-Host "Awesome! Your new Virtual Machine is ready to use." -ForegroundColor Green

    Return $NewVM

}
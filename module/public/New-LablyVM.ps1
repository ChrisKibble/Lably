Function New-LablyVM {

    [CmdLetBinding()]
    Param(

        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD,

        [Parameter(Mandatory=$False)]
        [String]$Template,

        [Parameter(Mandatory=$False)]
        [String]$DisplayName,

        [Parameter(Mandatory=$False)]
        [String]$Hostname = "LAB-$([Guid]::NewGuid().ToString().split('-')[0].ToUpper())",

        [Parameter(Mandatory=$True)]
        [String]$BaseVHD,

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

        [Parameter(Mandatory=$True)]
        [SecureString]$AdminPassword,

        [Parameter(Mandatory=$False)]
        [String]$Locale = $(Get-WinSystemLocale).Name,

        [Parameter(Mandatory=$False)]
        [Switch]$Force
    )

    $VMGUID = [GUID]::NewGuid().Guid

    $LablyScaffold = Join-Path $Path -ChildPath "scaffold.lably.json"

    If(-Not(Test-Path $LablyScaffold -ErrorAction SilentlyContinue)){
        Throw "There is no Lably at $Path."
    }

    Try {
        $Scaffold = Get-Content $LablyScaffold | ConvertFrom-Json
    } Catch {
        Throw "Unable to import Lably scaffold. $($_.Exception.Message)"
    }

    If($Scaffold.Secrets.SecretType -eq "PowerShell") {
        $SecretType = "PowerShell"
    } ElseIf($Scaffold.Secrets.SecretType -eq "KeyFile") {
        $SecretType = "KeyFile"
        Try {
            $SecretsKey = Get-Content $Scaffold.secrets.KeyFile
        } Catch {
            Throw "Unable to read Secrets key file."
        }
    } Else {
        Throw "Invalid secrets type in Scaffold File."
    }

    $SwitchId = $Scaffold.Meta.SwitchId

    If(-Not($SwitchId)) {
        Throw "Lably Scaffold missing SwitchId. File may be corrupt."
    }

    If(-Not(Get-VMSwitch -Id $SwitchId -ErrorAction SilentlyContinue)) {
        Throw "Switch in Lably Scaffold does not exist."
    }

    Try {
        $SwitchName = $(Get-VMSwitch -Id $SwitchId | Select-Object -First 1).Name
    } Catch {
        Throw "Unable to get name of switch $SwitchId."
    }

    If(-Not($DisplayName)) {
        $DisplayName = $Hostname
    }

    If($DisplayName -notlike "\[$($Scaffold.Meta.Name)\]*") {
        $DisplayName = "[$($Scaffold.Meta.Name)] $DisplayName"
    }

    If(Get-VM | Where-Object { $_.Name -eq $DisplayName }) {
        Throw "VM '$DisplayName' already exists."
    }

    $vhdRoot = Join-Path $Scaffold.Meta.VirtualDiskPath -ChildPath $VMGUID

    If(-Not($VHDRoot)) {
        Throw "No Virtual Disk Path defined in Lably Scaffold."
    }

    Try {
        $BaseImageRegistry = Get-Content $env:UserProfile\Lably\BaseImageRegistry.json -Raw | ConvertFrom-Json
    } Catch {
        Throw "Unable to read Base Image Registry. $($_.Exception.Message)"
    }
    
    $RegistryEntry = $BaseImageRegistry.BaseImages.Where{($_.ImagePath -eq $BaseVHD -or $_.FriendlyName -eq $BaseVHD)}[0]

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

        If(Test-Path $UserTemplateFile) {
            $TemplateFile = $UserTemplateFile
        } ElseIf(Test-Path $ModuleTemplateFile) {
            $TemplateFile = $ModuleTemplateFile
        } else {
            Throw "Cannot find $Template"
        }

        $LablyTemplate = Get-LablyTemplate $TemplateFile

        Write-Host ""
        Write-Host "Building: $($LablyTemplate.Meta.Name) v$($LablyTemplate.Meta.Version) by $($LablyTemplate.Meta.Author)." -ForegroundColor DarkGreen
        Write-Host ""

        $HostnameDefined = If($PSBoundParameters.ContainsKey("Hostname")) { $True } Else { $False }

        If(-Not(ValidateTemplate2BaseVHD -LablyTemplate $LablyTemplate -RegistryEntry $RegistryEntry -HostnameDefined $HostnameDefined)) {
            Throw "One or more of the requirements of this template were not met. Read the above warning messages for more information."
        }

        $InputResponse = Get-AnswersToInputQuestions -InputQuestions $LablyTemplate.Input

    }

    If(-Not(Test-Path $vhdRoot)) {
        Try {
            New-Item -ItemType Directory -Path $vhdRoot -ErrorAction Stop | Out-Null
        } Catch {
            Throw "Cannot create $vhdRoot. $($_.Exception.Message)"
        }
    
    }

    $OSVHDPath = Join-Path $vhdRoot -ChildPath "OSDisk.vhdx"

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
    Write-Host "Configuring VM Memory with Min=$([Math]::Round($MemoryMinimumInBytes/1GB,2))GB, Max=$([Math]::Round($MemoryMaximumInBytes/1GB,2))GB, Startup=$([Math]::Round($MemorySizeInBytes/1GB,2))GB,." -NoNewline

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
        
        $AdminPasswordAsBTSR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
        $AdminPasswordAsString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($AdminPasswordAsBTSR)

        If($SecretType -eq "PowerShell") {
            $SecureAdminPassword = $AdminPasswordAsString | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
        } ElseIf ($SecretType -eq "KeyFile") {
            $SecureAdminPassword = $AdminPasswordAsString | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $SecretsKey
        } Else {
            Throw "Unable to encrypt secrets, SecretType is not defined."
        }
        
        $ThisAsset = [PSCustomObject]@{
            DisplayName = $DisplayName
            CreatedUTC = $(Get-DateUTC)
            TemplateGuid = $TemplateGuid
            BaseVHD = $RegistryEntry.Id
            VMId = $NewVM.VMId
            AdminPassword = $SecureAdminPassword
        }

        If($InputResponse) {
            $ScaffoldResponse = $InputResponse | ConvertTo-Json -Depth 100 | ConvertFrom-Json
            
            ForEach($SecureProperty in $ScaffoldResponse | Where-Object { $_.Secure -eq $True }) {
                If($SecretType -eq "PowerShell") {
                    $SecureProperty.Val = $SecureProperty.Val | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
                } ElseIf ($SecretType -eq "KeyFile") {
                    $SecureProperty.Val = $SecureProperty.Val | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $SecretsKey
                } Else {
                    Throw "Unable to encrypt secrets, SecretType is not defined."
                }
            }

            Add-Member -InputObject $ThisAsset -MemberType NoteProperty -Name InputResponse -Value $ScaffoldResponse
        }
        
        [Array]$Scaffold.Assets += @($ThisAsset)

        $Scaffold | ConvertTo-Json -Depth 10 | Out-File $LablyScaffold -Force
        Write-Host " Success." -ForegroundColor Green
    } Catch {
        Write-Host " Warning!" -ForegroundColor Yellow
        Write-Warning "VM is online but we were unable to add it to your Lably scaffoling."
        Write-Warning $_.Exception.Message
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

    Write-Host "[VM] " -ForegroundColor Magenta -NoNewline
    Write-Host "Setting Network Type of Private and Enabling PSRemoting (You can change this later if desired)." -NoNewline
    
    Try {
        Invoke-Command -VMId $NewVM.VMId -ScriptBlock { 
            Start-Sleep -Seconds 15
            Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
            Enable-PSRemoting -Force | Out-Null 
        } -Credential $BuildAdministrator
        Write-Host " Success!" -ForegroundColor Green
    } Catch {
        Throw "Failed to enable PSRemoting. $($_.Exception.Message)"
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
                
                Switch($Step.Language) {
                    'PowerShell' {
                        Write-Host "Running PowerShell Script on VM as $($StepAdministrator.UserName)"

                        $StepScript = $Step.Script -join "`n"
                        $StepScript = Literalize -InputResponse $InputResponse -InputData $($StepScript)
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
    Write-Host "Comlpleted Running Post-Build Steps"

    Write-Host "Awesome! Your new Virtual Machine is ready to use." -ForegroundColor Green

    Return $NewVM

}
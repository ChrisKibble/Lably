Function New-Lably {

    [CmdLetBinding(DefaultParameterSetName='NewSwitch')]
    Param(
        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD,

        [Parameter(Mandatory=$False)]
        [String]$Name = (Split-Path $Path -Leaf),

        [Parameter(Mandatory=$False,ParameterSetName='NewSwitch')]
        [Parameter(Mandatory=$False,ParameterSetName='NewSwitchNAT')]
        [String]$CreateSwitch = (Split-Path $Path -Leaf),

        [Parameter(Mandatory=$True,ParameterSetName='NewSwitchNAT')]
        [ValidatePattern('^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')]
        [String]$NATIPAddress,

        [Parameter(Mandatory=$True,ParameterSetName='NewSwitchNAT')]
        [ValidatePattern('^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/\d{1,2}$')]
        [String]$NATRangeCIDR,

        [Parameter(Mandatory=$False,ParameterSetName='Switch')]
        [String]$Switch,

        [Parameter(Mandatory=$False)]
        [String]$VirtualDiskPath,

        [Parameter(Mandatory=$False)]
        [Switch]$SecretKeyFile

    )

    If(Get-ChildItem -Path $Path -ErrorAction SilentlyContinue) {
        Throw "Cannot create lably in $Path as it contains other files/folders. A Lably should be created in clean folders."
    }

    Try {
        If(-Not(Test-Path $Path)) {
            Write-Verbose "Creating $Path"
            New-Item -ItemType Directory -Path $Path | Out-Null
        }
    } Catch {
        Throw "Cannot Create $Path. $($_.Exception.Message)"
    }

    If($Switch) {
        Try {
            $VMSwitch = Get-VMSwitch -Name $Switch -ErrorAction Stop
        } Catch {
            Throw "Cannot get switch by Name '$Switch'. $($_.Exception.Message)"
        }
    }

    If($CreateSwitch) {

        $CreateSwitch = $CreateSwitch -replace "[^A-Za-z0-9 ]",""

        If(Get-VMSwitch -Name $CreateSwitch -ErrorAction SilentlyContinue) {
            Throw "Virtual Adapter '$CreateSwitch' already exists."
        }
        
        Try {
            Write-Verbose "Creating Switch '$CreateSwitch'."
            $VMSwitch = New-VMSwitch -Name $CreateSwitch -SwitchType Internal
        } Catch {
            Throw "Cannot create '$CreateSwitch'. $($_.Exception.Message)"
        }

        If($NATIPAddress) {

            If(Get-NetIPAddress -IPAddress $NATIPAddress) {
                Throw "NAT IP Address $NATIPAddress Already Exists on System. This must be unique."
            }

            Write-Verbose "Setting up NAT for Switch"
            $SwitchMAC = Get-VMNetworkAdapter -ManagementOS | Where-Object { $_.Name -eq $CreateSwitch } | Select-Object -ExpandProperty MacAddress
            Write-Verbose "Virtual Switch MAC Address is $SwitchMAC"
            If(-Not($SwitchMAC)) {
                Write-Warning "Could not find MAC Address of Virtual Swtitch. Aborting NAT setup."
                $VirtualAdapter = ""
            } Else {
                $VirtualAdapter = Get-NetAdapter | Where-Object { $($_.MacAddress -Replace '-','') -eq $SwitchMAC }
                Write-Verbose "Virtual Adapter is '$($VirtualAdapter.Name)'"
            }

            If(-Not($VirtualAdapter)) {
                Write-Warning "Could not find virtual adapter for MAC Address. Aborting NAT setup."
            } Else {
                Try {                  
                    Write-Verbose "Creating New NetIPAddress Bound to $($VirtualAdapter.Name)"
                    $PrefixLength = $($NATRangeCIDR -split '/')[1]
                    
                    ## This will die with the virtual ethernet adapter when the lab is removed, so no value in storing this in scaffold.
                    $NATIP = New-NetIPAddress -IPAddress $NATIPAddress -PrefixLength $PrefixLength -ifIndex ($VirtualAdapter.IfIndex) -ErrorAction Stop
                } Catch {
                    Throw "Could not create NetIPAddress. Aborting NAT Setup. $($_.Exception.Message)"
                }
            }

            If($NATIP) {
                Write-Verbose "Configuring New NAT Rule"
                Try {
                    $NewNAT = New-NetNat -Name "LablyNAT ($CreateSwitch)" -InternalIPInterfaceAddressPrefix $NATRangeCIDR                
                } Catch {
                    Write-Warning "Unable to create new NAT rule. Aborting NAT setup. $($_.Exception.Message)"
                }
            }
        }
    }

    If(-Not($VirtualDiskPath)) {
        $VirtualDiskPath = Join-Path $Path -ChildPath "Virtual Disks"
    }

    If($SecretKeyFile) {
        $SecretType = "KeyFile"
        Try {
            $KeyFilePath = Join-Path $env:USERPROFILE -ChildPath "Lably\Keys"
            If(-Not(Test-Path $KeyFilePath -ErrorAction SilentlyContinue)) {
                New-Item -ItemType Directory -Path $KeyFilePath -ErrorAction Stop | Out-Null
            }
        } Catch {
            Write-Warning "Could not create key file path. $($_.Exception.Message). Please manually create this folder."
        }

        Try {
            $KeyFile = Join-Path $KeyFilePath -ChildPath "$Name.$((New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds).key"
            $KeyAES = New-Object Byte[] 32
            [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($KeyAES)
            $KeyAES | Out-File $KeyFile
        } Catch {
            Throw "Unable to create secure key. $($_.Exception.Message)"
        }
    } else {
        $SecretType = "PowerShell"
        $KeyFile = $null
    }

    Try {
        Write-Verbose "Writing Scaffolding File"
        $ScaffoldFile = Join-Path $Path -ChildPath "scaffold.lably.json"
        [PSCustomObject]@{
            Meta = @{
                Name = $Name
                SwitchId = $VMSwitch.Id
                NATName = $(If($NewNAT) { $NewNAT.Name } else { $null })
                VirtualDiskPath = $VirtualDiskPath
                CreatedUTC = $(Get-DateUTC)
                ModifiedUTC = $(Get-DateUTC)
            }
            Secrets = @{
                SecretType = $SecretType
                KeyFile = $KeyFile
            }
        } | ConvertTo-Json | Out-File $ScaffoldFile -Force
    } Catch {
        Throw "Could not create Lably $Name. $($_.Exception.Message)"
    }

    If(-Not(Test-Path $VirtualDiskPath -ErrorAction SilentlyContinue)) {
        Try {
            Write-Verbose "Creating Virtual Disk Path $VirtualDiskPath"
            New-Item -ItemType Directory -Path $VirtualDiskPath -ErrorAction Stop | Out-Null
        } Catch {
            Write-Warning "Could not create $VirtualDiskPath. $($_.Exception.Message). Please manually create this folder."
        }
    }

    $TemplateCachePath = Join-Path $Path -ChildPath "Template Cache"

    If(-Not(Test-Path $TemplateCachePath -ErrorAction SilentlyContinue)) {
        Try {
            Write-Verbose "Creating Template Cache Path $TemplateCachePath"
            New-Item -ItemType Directory -Path $TemplateCachePath -ErrorAction Stop | Out-Null
        } Catch {
            Write-Warning "Could not create $TemplateCachePath. $($_.Exception.Message). Please manually create this folder."
        }
    }

    Write-Host "Congratulations! Your Lably '$Name'." -ForegroundColor Green
    If($SecretKeyFile) {
        Write-Host "Warning! Your key files are stored in $($KeyFilePath)." -ForegroundColor Yellow
        Write-Host "You're encouraged to **secure this folder** to ensure your lab secrets are kept safe." -ForegroundColor Yellow
    } Else {
        Write-Host "Your secrets are secured by your computer and user account." -ForegroundColor Yellow
        Write-Host "You may not be able to recover your secrets if your computer or user account changes." -ForegroundColor Yellow
    }

}
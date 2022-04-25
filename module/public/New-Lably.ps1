Function New-Lably {

    <#
    
    .SYNOPSIS

    Creates a new empty lab in the current directory or defined path.

    .DESCRIPTION

    This function is used to create a new Lably (lab or lab scaffold) that will be used to store the meta data for this specific lab. Function will create a scaffold.lably.json in the defined path that other Lably functions will use to store the metadata.

    .PARAMETER Path
    
    Optional parameter to define where the lably will be created. The scaffold, template cache, and (optionally) virtual disks folders will be created within this folder. If this parameter is not defined, it will default to the path from which the function was called.

    .PARAMETER Name

    Optional name of the Lably. Used as a description when using and describing the lab, as well as the default prefix for the display name of VMs created in Hyper-V. If this parameter is not defined, it will default to the name of the folder it's being created it.

    .PARAMETER CreateSwitch

    Name of switch to be created in Hyper-V for this lab. Either CreateSwitch or SwitchName are required. If neither parameter is defined, it will default creating a new switch using the name of the folder it's being created it.

    .PARAMETER Switch

    Name of exiting Hyper-V switch to be used for this lab. Either CreateSwitch or SwitchName are required. If neither parameter is defined, it will default creating a new switch using the name of the folder it's being created it.

    .PARAMETER NatIPAddress

    Optional parameter to be used when using CreateSwitch to define the IP Address to create for this network to use to access the host's network.

    .PARAMETER NatIPCIDRRange

    Optional parameter to be used to define the CIDR range of the VMs that will use the switch. Required if NatIPAddress is defined.

    .PARAMETER VirtualDiskPath

    Optional parameter to define the folder in which new differencing disks for this lab will be created when New-LablyVM is called. Defaults to a 'Virtual Disks' subfolder of the 'Path' parameter.

    .PARAMETER SecretKeyFile

    Switch used to indicate that instead of using the computer/user accounts to encrypt secrets that an AES key file should be created. When using keyfiles, ensure that appropriate NTFS permissions are set on your Lably folder to ensure that keys cannot be read by other users.

    .INPUTS

    None. You cannot pipe objects to New-Lably.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    New-Lably -Name "Chris' Lab"

    .EXAMPLE

    New-Lably -Name "Chris' Lab" -CreateSwitch "Test Switch #1"

    .EXAMPLE

    New-Lably -Name "Chris' Lab" -CreateSwitch "Test Switch #2" -NATIPAddress 10.0.0.1 -NATIPCIDRRange 10.0.0.0/24

    .EXAMPLE

    New-Lably -Name "Chris' Lab" -Switch "Existing Switch #3"

    .EXAMPLE

    New-Lably -Name "Chris' Lab" -VirtualDiskPath "D:\LabVMs" -SecretKeyFile

    #>

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

    ValidateModuleRun -RequiresAdministrator

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
        Write-Host "Should use switch $switch"
        Try {
            $VMSwitch = Get-VMSwitch -Name $Switch -ErrorAction SilentlyContinue
        } Catch {
            Throw "Cannot get switch by Name '$Switch'. $($_.Exception.Message)"
        }
    }

    If($PSBoundParameters.ContainsKey('HostName')) {

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

            If(Get-NetIPAddress -IPAddress $NATIPAddress -ErrorAction SilentlyContinue) {
                Throw "NAT IP Address $NATIPAddress Already Exists on System. This must be unique."
            }

            Write-Verbose "Setting up NAT for Switch"
            $SwitchMAC = Get-VMNetworkAdapter -ManagementOS | Where-Object { $_.Name -eq $CreateSwitch } | Select-Object -ExpandProperty MacAddress
            Write-Verbose "Virtual Switch MAC Address is $SwitchMAC"
            If(-Not($SwitchMAC)) {
                Write-Warning "Could not find MAC Address of Virtual Switch. Aborting NAT setup."
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
                NATIPCIDR = $NATRangeCIDR
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
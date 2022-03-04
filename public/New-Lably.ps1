Function New-Lably {

    [CmdLetBinding(DefaultParameterSetName='NewSwitch')]
    Param(
        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD,

        [Parameter(Mandatory=$False)]
        [String]$Name = (Split-Path $Path -Leaf),

        [Parameter(Mandatory=$False,ParameterSetName='NewSwitch')]
        [String]$NewSwitchName = (Split-Path $Path -Leaf),

        [Parameter(Mandatory=$True,ParameterSetName='Switch')]
        [String]$SwitchName,

        [Parameter(Mandatory=$True,ParameterSetName='SwitchId')]
        [String]$SwitchId,

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

    If($SwitchId) {
        Try {
            $VMSwitch = Get-VMSwitch -Id $SwitchId
        } Catch {
            Throw "Cannot get switch by Id '$SwitchId'. $($_.Exception.Message)"
        }
    }
    
    If($SwitchName) {
        Try {
            $VMSwitch = Get-VMSwitch -Name $SwitchName
        } Catch {
            Throw "Cannot get switch by Name '$SwitchName'. $($_.Exception.Message)"
        }
    }

    If($NewSwitchName) {
        If(Get-VMSwitch -Name $NewSwitchName -ErrorAction SilentlyContinue) {
            Throw "Virtual Adapter '$NewSwitchName' already exists."
        }
        Try {
            Write-Verbose "Creating Switch '$NewSwitchName'."
            $VMSwitch = New-VMSwitch -Name $NewSwitchName -SwitchType Internal
        } Catch {
            Throw "Cannot create '$NewSwitchName'. $($_.Exception.Message)"
        }
    }

    If(-Not($VirtualDiskPath)) {
        $VirtualDiskPath = Join-Path $Path -ChildPath "Virtual Disks"
    }

    If(-Not(Test-Path $VirtualDiskPath -ErrorAction SilentlyContinue)) {
        Try {
            Write-Verbose "Creating Virtual Disk Path $VirtualDiskPath"
            New-Item -ItemType Directory -Path $VirtualDiskPath -ErrorAction Stop | Out-Null
        } Catch {
            Throw "Could not create $VirtualDiskPath. $($_.Exception.Message)"
        }
    }

    If($SecretKeyFile) {
        $SecretType = "KeyFile"
        Try {
            $KeyFilePath = Join-Path $env:USERPROFILE -ChildPath "Lably\Keys"
            If(-Not(Test-Path $KeyFilePath -ErrorAction SilentlyContinue)) {
                New-Item -ItemType Directory -Path $KeyFilePath -ErrorAction Stop | Out-Null
            }
        } Catch {
            Throw "Could not create key file path. $($_.Exception.Message)"
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

    Write-Host "Congratulations! Your Lably '$Name'." -ForegroundColor Green
    If($SecretKeyFile) {
        Write-Host "Warning! Your key files are stored in $($KeyFilePath)." -ForegroundColor Yellow
        Write-Host "You're encouraged to **secure this folder** to ensure your lab secrets are kept safe." -ForegroundColor Yellow
    } Else {
        Write-Host "Your secrets are secured by your computer and user account." -ForegroundColor Yellow
        Write-Host "You may not be able to recover your secrets if your computer or user account changes." -ForegroundColor Yellow
    }

}
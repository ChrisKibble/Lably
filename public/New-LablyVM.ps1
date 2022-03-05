Function New-LablyVM {

    [CmdLetBinding()]
    Param(

        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD,

        [Parameter(Mandatory=$False)]
        [String]$DisplayName,

        [Parameter(Mandatory=$True)]
        [String]$BaseVHD,

        [Parameter(Mandatory=$False)]
        [String]$Hostname = "LAB-$([Guid]::NewGuid().ToString().split('-')[0].ToUpper())",

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

        [Parameter(Mandatory=$False,DontShow=$True)]
        [String]$TemplateGuid = "",

        [Parameter(Mandatory=$False)]
        [Switch]$Force
    )

    Write-Host "Starting Process to Create New Virtual Machine ..."

    $VMGUID = [GUID]::NewGuid().Guid

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

    $SwitchId = $Scaffold.Meta.SwitchId

    If(-Not($SwitchId)) {
        Throw "Lably Scaffold missing SwitchId. File may be corrupt."
    }

    If(-Not(Get-VMSwitch -Id $SwitchId -ErrorAction SilentlyContinue)) {
        Throw "Switch in Lably Scaffold does not exist."
    }

    Try {
        $SwitchName = $(Get-VMSwitch -Id $SwitchId | Select-Object -First 1).Name
        Write-Verbose "Using Switch $SwitchName"    
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
    Write-Verbose "Using $vhdRoot as the VHD Root for this VM"

    If(-Not($VHDRoot)) {
        Throw "No Virtual Disk Path defined in Lably Scaffold."
    }

    If(-Not(Test-Path $vhdRoot)) {
        Try {
            Write-Verbose "Creating $vhdRoot"
            New-Item -ItemType Directory -Path $vhdRoot -ErrorAction Stop | Out-Null
        } Catch {
            Throw "Cannot create $vhdRoot. $($_.Exception.Message)"
        }
    
    }

    $OSVHDPath = Join-Path $vhdRoot -ChildPath "OSDisk.vhdx"

    If($(Test-Path $OSVHDPath) -and $Force) {
        Try {
            Write-Verbose "Removing $OSVHDPath"
            Remove-Item $OSVHDPath -Force -ErrorAction Stop
        } Catch {
            Throw "Could not remove $OSVHDPath. $($_.Exception.Message)"
        }
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
    
    Write-Verbose "Will use BaseVHD $($BaseVHD)."
    
    If(-Not($ProductKey)) {
        Write-Verbose "No product key defined in call to this function, will use ProductKey from BaseVHD Registry."
        $ProductKey = $RegistryEntry.ProductKey
    }

    Write-Host "Creating New VHD for VM ..."

    Try {
        Write-Verbose "Creating $OSVHDPath"
        $VHD = New-VHD -Differencing -Path $OSVHDPath -ParentPath $BaseVHD -ErrorAction Stop
    } Catch {
        Throw "Cannot create $OSVHDPath. $($_.Exception.Message)"
    }    

    Write-Host "Creating Operating System on VM ..."

    Try {
        Write-Verbose "Mounting New VHD"
        $vhdMount = Mount-VHD -Path $VHD.Path -Passthru -ErrorAction Stop
    } Catch {
        Remove-Item $VHD.Path -ErrorAction SilentlyContinue
        Throw "Could not mount $($VHD.Path). $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Getting Drive Letter for New VHD"
        $VHDDriveLetter = $(Get-Partition -DiskNumber $VHDMount.DiskNumber | Where-Object { $_.Type -eq "Basic" -and $_.DriveLetter })[0].DriveLetter
        [String]$VHDDriveLetter += ":"
        Write-Verbose "Drive Letter for New VHD is $VHDDriveLetter"
    } Catch {
        Dismount-Vhd -Path $VHD.Path -ErrorAction SilentlyContinue
        Remove-Item $VHD.Path -ErrorAction SilentlyContinue
        Throw "Could not get drive letter from $($VHD.Path). $($_.Exception.Message)"
    }

    Try {
        $unattendPath = Join-Path $VHDDriveLetter -ChildPath "Windows\Panther"
        If(-Not(Test-Path $unattendPath)) {
            Write-Verbose "Creating $unattendPath"
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

        Write-Verbose "Writing Unattend File to $unattendFile"

        $xmlUnattend.Save($unattendFile)

    } Catch {
        Dismount-Vhd -Path $VHD.Path -ErrorAction SilentlyContinue
        Remove-Item $VHD.Path -ErrorAction SilentlyContinue
        Throw "Could not setup Unattend on VHD. $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Dismounting VHD"
        Dismount-Vhd -Path $VHD.Path -ErrorAction Stop
    } Catch {
        Write-Warning "Could not dismount $($VHD.Path), you'll need to manually dismount or reboot before using. $($_.Exception.Message)"
    }

    Write-Host "Setting up VM in Hyper-V."

    Try {
        Write-Verbose "Creating New VM $DisplayName"
        $NewVM = New-VM -Name $DisplayName -MemoryStartupBytes $MemorySizeInBytes -VHDPath $VHD.Path -Generation 2 -SwitchName $SwitchName -ErrorAction Stop
    } Catch {
        Remove-Item $VHD.Path -ErrorAction SilentlyContinue
        Throw "Could not create $DisplayName. $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Configuring VM Memory"
        Set-VMMemory -VMName $DisplayName -MinimumBytes $MemoryMinimumInBytes -MaximumBytes $MemoryMaximumInBytes -ErrorAction Stop
    } Catch {
        Write-Warning "Unable to change VM CPU Settings. $($_.Exception.Message)"        
    }

    Try {
        Write-Verbose "Configuring VM CPU"
        Set-VMProcessor -VMName $DisplayName -Count $CPUCount -ErrorAction Stop
    } Catch {
        Write-Warning "Unable to change VM CPU Settings. $($_.Exception.Message)"        
    }

    Try {
        $Scaffold = Get-Content $LablyScaffold | ConvertFrom-Json
        If(-Not($Scaffold.Assets)) {
            Add-Member -InputObject $Scaffold -MemberType NoteProperty -Name Assets -Value @() -ErrorAction SilentlyContinue
        }
        $Scaffold.Assets += @(
            [PSCustomObject]@{
                DisplayName = $DisplayName
                TemplateGuid = $TemplateGuid
                BaseVHD = $BaseVHD
                VMId = $NewVM.VMId
                CreatedUTC = $(Get-DateUTC)
            }
        )
        $Scaffold | ConvertTo-Json | Out-File $LablyScaffold -Force
    } Catch {
        Write-Warning "VM is online but we were unable to add it to your Lably scaffoling."
        Write-Warning $_.Exception.Message
    }

    Write-Host "Awesome! Your new Virtual Machine is ready to use." -ForegroundColor Green

    Return $NewVM

}
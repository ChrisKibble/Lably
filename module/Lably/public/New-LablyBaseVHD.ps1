Function New-LablyBaseVHD {

    <#
    
    .SYNOPSIS

    Creates a new Base VHD file for use in creating new VMs.

    .DESCRIPTION

    This function is used to creates a new Base VHD file for use in creating new VMs. It is not tied to any specific lab, any lab can use any of the Base VHDs. Once the VHD is created, the Register-LablyBaseVHD should be used to add it to the image registry.

    .PARAMETER ISO
    
    Full or relative path to the ISO that has the Operating System installer on it.

    .PARAMETER VHD

    Full or relative path to where the Base VHD should be created.

    .PARAMETER VHDSizeInBytes

    Optional size of the Base VHD. As the VHD expands to fit the content and doesn't use the full space unless necessary, there is unlikely to be a value in setting this parameter. Defaults to 127GB.

    .PARAMETER Index

    Index number of the Operating System to create the Base VHD for. Default to 1. If you're unsure of the Index Number, use Get-LablyISODetails to identify it.

    .PARAMETER Force

    Switch that defines that the VHD should be overwritten if the file exists.

    .INPUTS

    None. You cannot pipe objects to New-LablyBaseVHD.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    New-LablyBaseVHD -ISO C:\ISOs\Windows10-Enterprise.iso -Index 4 -VHD C:\VHDRepo\Win10Ent.vhdx

    #>

    [CmdLetBinding(DefaultParameterSetName='OSByIndex')]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [String]$ISO,

        [Parameter(Mandatory=$True,Position=1)]
        [String]$VHD,

        [Parameter(Mandatory=$False)]
        [Int64]$VHDSizeInBytes = 127GB,

        [Parameter(Mandatory=$False)]
        [Int]$Index = 1,

        [Parameter(Mandatory=$False)]
        [Switch]$Force
    )

    ValidateModuleRun -RequiresAdministrator

    # Credit: Help with this function from: https://github.com/greyhamwoohoo/new-vm-from-iso

    $gptTypeEFI = "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
    $gptTypeMSR = "{e3c9e316-0b5c-4db8-817d-f92df00215ae}"

    Write-Host "Creating new VHDx from $ISO Index $Index"

    If($(Test-Path $VHD) -and $($Force -eq $False)) {
        Throw "File $VHD Already Exists. Use -Force to Overwrite."
    }

    Try {
        Write-Verbose "Mounting $ISO"
        $mnt = Mount-DiskImage -ImagePath $ISO 
        $mntVolume = $($mnt | Get-Volume).DriveLetter
    } Catch {
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Throw "Could not mount ISO. $($_.Exception.Message)"
    }
    
    Write-Verbose "Mounted $ISO to $mntVolume"

    $WIM = "$mntVolume`:\Sources\Install.wim"

    Write-Verbose "Looking for $WIM"
    If(-Not(Test-Path $WIM)) {
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Throw "Unable to find \Source\Install.wim in ISO $ISO"
    }

    Try {
        $DiskImages = Get-WindowsImage -ImagePath $WIM
        $ImageIndexes = $DiskImages | Select-Object -ExpandProperty ImageIndex
        If($Index -notin $ImageIndexes) {
            Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
            Throw "Image Index #$Index is not in the range of valid indexes in WIM."    
        }
    } Catch {
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Throw "Unable get Windows Images from $WIM. $($_.Exception.Message)"
    }

    If(Test-Path $VHD) {
        Try {
            Remove-Item $VHD -Force
        } Catch {
            Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
            Throw "Unable to overwrite $VHD. $($_.Exception.Message)"
        }
    }

    Try {
        Write-Verbose "Creating $VHD"
        $DiskFile = New-VHD -Path $VHD -SizeBytes $VHDSizeInBytes -Dynamic -ErrorAction Stop
    } Catch {
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Throw "Unable to Create VHD. $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Mounting $VHD"
        $vhdMount = Mount-Vhd -Path $DiskFile.Path -Passthru -ErrorAction Stop
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Remove-Item $VHD -ErrorAction SilentlyContinue
        Throw "Unable to Mount VHD $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Getting Disk of $VHD"
        $vhdDisk = $vhdMount | Get-Disk
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Remove-Item $VHD -ErrorAction SilentlyContinue
        Throw "Unable to Get Disk from VHD $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Initializing VHD (Disk Number $($vhdDisk.DiskNumber))"
        Initialize-Disk -Number $vhdDisk.DiskNumber -PartitionStyle GPT -Passthru -ErrorAction Stop | Out-Null
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Remove-Item $VHD -ErrorAction SilentlyContinue
        Throw "Unable to Initialize VHD. $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Creating EFI Partition on $VHD"
        $diskPartSystem = New-Partition -DiskNumber $vhdDisk.DiskNumber -Size 100MB -GptType $gptTypeEFI -AssignDriveLetter -ErrorAction Stop

        Write-Verbose "Creating Microsoft Reserved Partition on $VHD"
        New-Partition -DiskNumber $vhdDisk.DiskNumber -Size 128MB -GptType $gptTypeMSR -ErrorAction Stop | Out-Null

        Write-Verbose "Creating Primary Partitions on $VHD"
        $diskPartPrimary = New-Partition -DiskNumber $vhdDisk.DiskNumber -UseMaximumSize -AssignDriveLetter -ErrorAction Stop
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Remove-Item $VHD -ErrorAction SilentlyContinue
        Throw "Unable to Create Partition. $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Formatting System Partition $($diskPartSystem.DriveLetter):"
        Format-Volume -DriveLetter $($DiskPartSystem.DriveLetter) -FileSystem FAT32 -NewFileSystemLabel "System" -ErrorAction Stop | Out-Null
        Write-Verbose "Formatting Primary Partition $($diskPartPrimary.DriveLetter):"
        Format-Volume -DriveLetter $($diskPartPrimary.DriveLetter) -FileSystem NTFS -NewFileSystemLabel "OSDisk" -ErrorAction Stop | Out-Null
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Remove-Item $VHD -ErrorAction SilentlyContinue
        Throw "Unable to Format Volume. $($_.Exception.Message)"
    }

    Try {
        Write-Host "Expanding Index $index of $WIM to $($diskPartPrimary.DriveLetter):"
        Expand-Windowsimage -ImagePath $WIM -ApplyPath "$($diskPartPrimary.DriveLetter):\" -Index $index -ErrorAction Stop | Out-Null
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Remove-Item $VHD -ErrorAction SilentlyContinue
        Throw "Unable to Expand WIM. $($_.Exception.Message)"
    }

    Try {
        Write-Verbose "Making Disk Bootable with OS Drive $($diskPartPrimary.DriveLetter): and System Drive $($diskPartSystem.DriveLetter):"
        Start-Process bcdboot.exe -ArgumentList @("$($diskPartPrimary.DriveLetter):\Windows", "/s $($diskPartSystem.DriveLetter):", "/f UEFI") -WorkingDirectory "$($diskPartPrimary.DriveLetter):\Windows\System32" -WindowStyle Hidden -Wait
    } Catch {
        Dismount-Vhd -Path $VHD -ErrorAction SilentlyContinue
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Remove-Item $VHD -ErrorAction SilentlyContinue
        Throw "Unable to Make Disk Bootable. $($_.Exception.Message)"
    }

    Write-Host "Cleaning up..."

    Try {
        Dismount-Vhd -Path $VHD -ErrorAction Stop
    } Catch {
        Write-Warning "Could not dismount $VHD, you'll need to manually dismount or reboot before using. $($_.Exception.Message)"
    }

    Try {
        Dismount-DiskImage -ImagePath $ISO -ErrorAction Stop | Out-Null
    } Catch {
        Write-Warning "Unable to dismount ISO image. This will automatically dismount at reboot or you can try and do so manually."
    }

    Write-Host "Awesome! You've got yourself a new base image at the following path. You can use this to build VMs!" -ForegroundColor Green
    Write-Host "You should register this Base VHD with Lably using: " -NoNewline
    Write-Host "Register-LablyBaseVHD -VHD $VHD" -ForegroundColor Gray

}

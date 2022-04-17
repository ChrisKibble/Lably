Function New-LablyBaseVHD {

    [CmdLetBinding(DefaultParameterSetName='OSByIndex')]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [String]$ISO,

        [Parameter(Mandatory=$True,Position=1)]
        [String]$VHD,

        [Parameter(Mandatory=$False,ParameterSetName='OSByIndex')]
        [Int]$Index = 1,

        [Parameter(Mandatory=$False,ParameterSetName='OSByEdition')]
        [String]$OSEdition,

        [Parameter(Mandatory=$False)]
        [Switch]$Force
    )

    # Credit: Help with this function from: https://github.com/greyhamwoohoo/new-vm-from-iso

    ## Assumes Windows - Need to extend in the future to support non-Windows build.

    ## TODO: validate index
    ## TODO: Parameter for VHDx Size

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
        $DiskFile = New-VHD -Path $VHD -SizeBytes 127GB -Dynamic -ErrorAction Stop
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
        Write-Verbose "Initalizing VHD (Disk Number $($vhdDisk.DiskNumber))"
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

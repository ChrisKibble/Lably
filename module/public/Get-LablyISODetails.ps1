Function Get-LablyISODetails {

    [CmdLetBinding()]
    Param(
        [String]$ISO
    )

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

    Try {
        Write-Verbose "Getting Disk Image Information from $WIM"
        $imageDetails = Get-WindowsImage -ImagePath $WIM
    } Catch {
        Throw "Unable to get Image Information. $($_.Exception.Message)"
    }

    Try {
        Dismount-DiskImage -ImagePath $ISO -ErrorAction Stop | Out-Null
    } Catch {
        Write-Warning "Unable to dismount ISO image. This will automatically dismount at reboot or you can try and do so manually."
    }

    Return $imageDetails

}

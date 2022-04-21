Function Get-LablyISODetails {

    <#
    
    .SYNOPSIS

    Gets the details from the WIM inside of a supplied ISO.

    .DESCRIPTION

    Gets the details from the WIM inside of a supplied ISO. Takes the path of the ISO as a parameter.

    .PARAMETER ISO
    
    Full or relative path to the ISO file to get details on.
    
    .INPUTS

    None. You cannot pipe objects to Get-LablyISODetails.

    .OUTPUTS

    System.Collections.Generic.List`1[[Microsoft.Dism.Commands.WimImageInfoObject,
    Microsoft.Dism.PowerShell, Version=10.0.0.0, Culture=neutral, PublicKeyToken=null]]
    System.Collections.Generic.List`1[[Microsoft.Dism.Commands.ImageInfoObject, Microsoft.Dism.PowerShell,
    Version=10.0.0.0, Culture=neutral, PublicKeyToken=null]]
    System.Collections.Generic.List`1[[Microsoft.Dism.Commands.BasicImageInfoObject,
    Microsoft.Dism.PowerShell, Version=10.0.0.0, Culture=neutral, PublicKeyToken=null]]
    System.Collections.Generic.List`1[[Microsoft.Dism.Commands.MountedImageInfoObject,
    Microsoft.Dism.PowerShell, Version=10.0.0.0, Culture=neutral, PublicKeyToken=null]]
    
    .EXAMPLE

    Get-LablyISODetais -ISO C:\ISOs\Windows10-Enterprise.iso

    #>

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

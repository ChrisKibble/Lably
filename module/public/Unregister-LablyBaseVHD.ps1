Function Unregister-LablyBaseVHD {

    <#
    
    .SYNOPSIS

    Unregisters a Base VHD from the Lably Base Image Registry.

    .DESCRIPTION

    This function is used to unregister a Base VHD from the Lably Base Image Registry that is stored in the Lably subfolder of your user profile. The Base Image Registry is used when creating new VMs.

    .PARAMETER VHD
    
    Full path to the Base VHD. Either VHD, ID, or FriendlyName are required. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .PARAMETER ID
    
    Registry ID of the Base VHD. Either VHD, ID, or FriendlyName are required. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .PARAMETER FriendlyName
    
    Friendly name for the Base VHD. Either VHD, ID, or FriendlyName are required. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .INPUTS

    None. You cannot pipe objects to Register-LablyBaseVHD.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    Unregister-LablyBaseVHD -VHD C:\BaseVHDs\Windows10-Ent.vhdx

    .EXAMPLE

    Unregister-LablyBaseVHD -ID "491e26d4-b6da-4828-b6ee-318536646f75"

    .EXAMPLE

    Unregister-LablyBaseVHD -FriendlyName "Windows 10 Enterprise (April 2022)"

    #>

    [CmdLetBinding(DefaultParameterSetName='VHD')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName='VHD')]
        [String]$VHD,

        [Parameter(Mandatory=$True,ParameterSetName='ID')]
        [String]$ID,

        [Parameter(Mandatory=$True,ParameterSetName='FriendlyName')]
        [String]$FriendlyName
    )    

    ValidateModuleRun -RequiresAdministrator

    $imageRegistryDirectory = Join-Path $env:USERPROFILE -ChildPath "Lably"
    $imageRegistry = Join-Path $imageRegistryDirectory -ChildPath "BaseImageRegistry.json"

    Try {
        Write-Verbose "Importing Existing Registry Directory"
        $RegistryObject = Get-Content $imageRegistry -Raw | ConvertFrom-Json
    } Catch {
        Throw "Could not load $imageRegistry. $($_.Exception.Message)"
    }

    If($VHD) {
        $Entry = $RegistryObject.BaseImages | Where-Object { $_.ImagePath -eq $VHD }
    } ElseIf($ID) {
        $Entry = $RegistryObject.BaseImages | Where-Object { $_.ID -eq $ID }
    } ElseIf($FriendlyName) {
        $Entry = $RegistryObject.BaseImages | Where-Object { $_.FriendlyName -eq $FriendlyName }
    }

    If(-Not($Entry)) {
        Throw "No such Base VHD was found."
    }

    If($Entry.Count -gt 1) {
        Throw "More than one Base VHD was found that met those criteria. Use the VHD Path or ID instead."
    }

    $RegistryObject.Meta.ModifiedDateUTC = $(Get-DateUTC)
    $RegistryObject.BaseImages = $RegistryObject.BaseImages | Where-Object { $_.ID -ne $Entry.Id }

    Try {
        Write-Verbose "Exporting Registry Data to $ImageRegistry"
        $RegistryObject | ConvertTo-Json | Out-File $ImageRegistry -Force
    } Catch {
        Throw "Unable to save registry. $($_.Exception.Message)"
    }

    Write-Host "BaseVHD has been unregistered."
    Write-Host "The VHD has not been deleted, you can manually delete the following file if no longer in use:"
    Write-Host $Entry.ImagePath

}

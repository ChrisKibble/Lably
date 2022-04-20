Function Unregister-LablyBaseVHD {
    [CmdLetBinding(DefaultParameterSetName='VHD')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName='VHD')]
        [String]$VHD,

        [Parameter(Mandatory=$True,ParameterSetName='ID')]
        [String]$ID,

        [Parameter(Mandatory=$True,ParameterSetName='FriendlyName')]
        [String]$FriendlyName
    )    

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
    Write-Host "The VHD  has not been deleted, you can manually delete the following file if no longer in use:"
    Write-Host $Entry.ImagePath

}

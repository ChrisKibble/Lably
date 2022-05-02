Function Get-LablyBaseVHDRegistry {

    <#
    
    .SYNOPSIS

    Gets list of Lably Base VHDs from Registry

    .DESCRIPTION

    This function is used to display the Base VHDs currently stored in the Base VHD Registry.

    .PARAMETER Meta
    
    Switch to get the meta data from the registry instead of the Base VHDs.

    .INPUTS

    None. You cannot pipe objects to Get-LablyBaseVHDRegistry.

    .OUTPUTS

    Array of Base VHDs from Registry.
    
    .EXAMPLE

    Get-LablyBaseVHDRegistry

    .EXAMPLE

    Get-LablyBaseVHDRegistry -Meta

    #>

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [Switch]$Meta
    )    

    $imageRegistryDirectory = Join-Path $env:USERPROFILE -ChildPath "Lably"
    $imageRegistry = Join-Path $imageRegistryDirectory -ChildPath "BaseImageRegistry.json"

    Try {
        Write-Verbose "Importing Existing Registry Directory"
        $RegistryObject = Get-Content $imageRegistry -Raw | ConvertFrom-Json
    } Catch {
        Throw "Could not load $imageRegistry. $($_.Exception.Message)"
    }

    If(-Not($Meta)) {
        Return $RegistryObject.BaseImages
    } Else {
        Return $RegistryObject.Meta
    }

}

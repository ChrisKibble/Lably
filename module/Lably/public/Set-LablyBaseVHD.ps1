Function Set-LablyBaseVHD {

    <#
    
    .SYNOPSIS

    Sets specific options in Base VHD registry

    .DESCRIPTION

    This function is used to set properties of Base VHDs in the Base VHD Registry.

    .PARAMETER VHD
    
    Full path to the Base VHD. Either VHD, ID, or FriendlyName are required. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .PARAMETER ID
    
    Registry ID of the Base VHD. Either VHD, ID, or FriendlyName are required. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .PARAMETER FriendlyName
    
    Friendly name for the Base VHD. Either VHD, ID, or FriendlyName are required. This parameter supports auto-complete, you can tab through options or use CTRL+SPACE to view all options.

    .PARAMETER NewVHDPath
    
    Optional New Path for Base VHD. Will validate that the file exists unless -Force is specified.

    .PARAMETER NewFriendlyName
    
    Optional New Friendly New for this Base VHD.

    .PARAMETER NewOSEdition
    
    Optional New OS Edition for this Base VHD. This updates the registry only and not the VHD file.

    .PARAMETER NewOSVersion
    
    Optional New OS Version for this Base VHD. This updates the registry only and not the VHD file.

    .PARAMETER NewProductKey
    
    Optional New OS Product Key for this Base VHD. This updates the registry only and not the VHD file.

    .PARAMETER Force

    Switch that will set the new Base VHD Path even if it doesn't exist.

    .INPUTS

    None. You cannot pipe objects to Register-LablyBaseVHD.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    Set-LablyBaseVHD -VHD C:\BaseVHDs\Windows10-Ent.vhdx

    .EXAMPLE

    Set-LablyBaseVHD -ID "491e26d4-b6da-4828-b6ee-318536646f75"

    .EXAMPLE

    Set-LablyBaseVHD -FriendlyName "Windows 10 Enterprise (April 2022)"

    #>

    [CmdLetBinding(DefaultParameterSetName='VHD')]
    Param(
        [Parameter(Mandatory=$True,ParameterSetName='VHD')]
        [String]$VHD,

        [Parameter(Mandatory=$True,ParameterSetName='ID')]
        [String]$ID,

        [Parameter(Mandatory=$True,ParameterSetName='FriendlyName')]
        [String]$FriendlyName,
    
        [Parameter(Mandatory=$False)]
        [String]$NewVHDPath,

        [Parameter(Mandatory=$False)]
        [String]$NewFriendlyName,

        [Parameter(Mandatory=$False)]
        [String]$NewOSEdition,

        [Parameter(Mandatory=$False)]
        [String]$NewOSVersion,

        [Parameter(Mandatory=$False)]
        [String]$NewProductKey,

        [Parameter(Mandatory=$False)]
        [Switch]$Force

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

    If($NewVHDPath) {
        If(-Not($Force)) {
            If(-Not(Test-Path $NewVHDPath -ErrorAction SilentlyContinue)) {
                Throw "Cannot find $NewVHDPath"
            }
        }

        $Entry.ImagePath = $NewVHDPath
    }

    If($NewFriendlyName) { $Entry.FriendlyName = $NewFriendlyName }
    If($NewOSEdition) { $Entry.OSEdition = $NewOSEdition }
    If($NewOSVersion) { $Entry.OSVersion = $NewOSVersion }
    If($NewProductKey) { $Entry.ProductKey = $NewProductKey }

    Try {
        Write-Verbose "Exporting Registry Data to $ImageRegistry"
        $RegistryObject | ConvertTo-Json | Out-File $ImageRegistry -Force
    } Catch {
        Throw "Unable to save registry. $($_.Exception.Message)"
    }

    Write-Host "BaseVHD Registry has been Updated."
    If($NewOSEdition -or $NewOSVersion) {
        Write-Host "It is suggested you use Test-LablyBaseVHDRegistry to ensure consistency."
    }

}

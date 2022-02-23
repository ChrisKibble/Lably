Function Update-Unattend {

    [CmdLetBinding()]
    Param(

        [Parameter(Mandatory=$True)]
        [XML]$xmlUnattend,

        [Parameter(Mandatory=$True)]
        [String]$ComputerName,

        [Parameter(Mandatory=$False)]
        [String]$ProductKey,

        [Parameter(Mandatory=$True)]
        [String]$Timezone,

        [Parameter(Mandatory=$True)]
        [SecureString]$AdminPassword,

        [Parameter(Mandatory=$True)]
        [String]$Locale
    )

    $oobe = $xmlUnattend.unattend.settings.where{ $_.pass -eq "oobeSystem" } | Select-Object -First 1
    $specialize = $xmlUnattend.unattend.settings.where{ $_.pass -eq "specialize" } | Select-Object -First 1
    
    $oobeIntl = $oobe.component.where{ $_.name -eq "Microsoft-Windows-International-Core" } | Select-Object -First 1
    $specializeIntl = $specialize.component.where{ $_.name -eq "Microsoft-Windows-International-Core" } | Select-Object -First 1

    $oobeShell = $oobe.component.where{ $_.name -eq "Microsoft-Windows-Shell-Setup" } | Select-Object -First 1
    $specializeShell = $specialize.component.where{ $_.name -eq "Microsoft-Windows-Shell-Setup" } | Select-Object -First 1

    # User Loacle oobe
    Write-Verbose "Writing Input Locales to OOBE XML"
    $oobeIntl.InputLocale = $Locale
    $oobeIntl.SystemLocale = $Locale
    $oobeIntl.UILanguage = $Locale
    $oobeIntl.UILanguageFallback = $Locale
    $oobeIntl.UserLocale = $Locale

    # User Locale Specialize
    Write-Verbose "Writing Input Locales to Specialize XML"
    $specializeIntl.InputLocale = $Locale
    $specializeIntl.SystemLocale = $Locale
    $specializeIntl.UILanguage = $Locale
    $specializeIntl.UILanguageFallback = $Locale
    $specializeIntl.UserLocale = $Locale
    
    # Computer Name
    Write-Verbose "Writing Computer Name XML" 
    $specializeShell.ComputerName = $ComputerName

    # Time Zone
    Write-Verbose "Writing Time Zone XML"
    $specializeShell.TimeZone = $Timezone

    # Admin Password
    Write-Verbose "Writing Admin Password to XML"
    $oobeShell.UserAccounts.AdministratorPassword.Value = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))

    # Product Key
    If($ProductKey) {
        Write-Verbose "Writing Product $ProductKey Key to XML"
        Try {
            [System.Xml.XmlNode]$xmlProductKey = $xmlUnattend.CreateElement("ProductKey")
            $xmlProductKey.InnerText = $ProductKey
            $specializeShell.AppendChild($xmlProductKey) | Out-Null   
        } Catch {
            Write-Warning "Unable to setup product key. $($_.Exception.Message)"
        }
    }

    Return $xmlUnattend
}

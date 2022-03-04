Function Update-Unattend {

    [CmdLetBinding()]
    Param(

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

$xmlData = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
     <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>*</ComputerName>
             <TimeZone>GMT Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>*</ComputerName>
             <TimeZone>GMT Standard Time</TimeZone>
        </component>
    </settings>
    <settings pass="oobeSystem">
         <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-us</InputLocale>
            <SystemLocale>en-us</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UserLocale>en-us</UserLocale>
        </component>
            <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-us</InputLocale>
            <SystemLocale>en-us</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UserLocale>en-us</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>password</Value>
                    <PlainText>True</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                   <LocalAccount wcm:action="add">
                       <Password>
                           <Value>password</Value>
                           <PlainText>True</PlainText>
                       </Password>
                       <DisplayName>Administrator</DisplayName>
                       <Group>Administrators</Group>
                       <Name>Administrator</Name>
                   </LocalAccount>
               </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Password>
                    <Value>password</Value> 
                    <PlainText>true</PlainText> 
                </Password>
                <Username>Administrator</Username> 
                <Enabled>true</Enabled> 
                <LogonCount>1</LogonCount> 
            </AutoLogon>   
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>password</Value>
                    <PlainText>True</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                   <LocalAccount wcm:action="add">
                       <Password>
                           <Value>password</Value>
                           <PlainText>True</PlainText>
                       </Password>
                       <DisplayName>Administrator</DisplayName>
                       <Group>Administrators</Group>
                       <Name>Administrator</Name>
                   </LocalAccount>
               </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Password>
                    <Value>password</Value> 
                    <PlainText>true</PlainText> 
                </Password>
                <Username>Administrator</Username> 
                <Enabled>true</Enabled> 
                <LogonCount>1</LogonCount> 
            </AutoLogon>   
          </component>
    </settings>
</unattend>
"@

    $oobe = $xmlData.unattend.settings | Where-Object { $_.pass -eq "oobeSystem" }
    $specialize = $xmlData.unattend.settings | Where-Object { $_.pass -eq "specialize" } | Select-Object -First 1
    
    $oobeIntl = $oobe.component | Where-Object { $_.name -eq "Microsoft-Windows-International-Core" }
    $oobeShell = $oobe.component | Where-Object { $_.name -eq "Microsoft-Windows-Shell-Setup" }
    $specializeShell = $specialize.component | Where-Object { $_.name -eq "Microsoft-Windows-Shell-Setup" }

    # User Loacle oobe
    Write-Verbose "Writing Input Locale $Locale to OOBE XML"
    ForEach($component in $oobeIntl) {
        $component.InputLocale = $Locale
        $component.SystemLocale = $Locale
        $component.UILanguage = $Locale
        $component.UserLocale = $Locale    
    }
    
    # Computer Name & TimeZone
    Write-Verbose "Writing Computer ($ComputerName) & Timezone ($TimeZone) to XML" 
    ForEach($component in $specializeShell) {
        $component.ComputerName = $ComputerName
        $component.Timezone = $TimeZone
    }

    # Admin Password
    Write-Verbose "Writing Admin Password to XML"
    ForEach($component in $oobeShell) {
        $component.UserAccounts.AdministratorPassword.Value = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))
        $component.UserAccounts.LocalAccounts.LocalAccount.Password.Value = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))
        $component.AutoLogon.Password.Value = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))
    }

    # Product Key
    If($ProductKey) {
        Write-Verbose "Writing Product $ProductKey Key to XML"
        Try {
            ForEach($component in $specializeShell) {
                [System.Xml.XmlNode]$xmlProductKey = $xmlData.CreateElement("ProductKey", $component.NamespaceURI)
                $xmlProductKey.InnerText = $ProductKey
                $component.AppendChild($xmlProductKey) | Out-Null                   
            }
        } Catch {
            Write-Warning "Unable to setup product key. $($_.Exception.Message)"
        }
    }

    # TODO - Remove This
    Write-Verbose "Saving Copy of XML at $env:temp\unattend.xml"
    $xmlData.Save("$env:temp\unattend.xml")

    Return $xmlData
}

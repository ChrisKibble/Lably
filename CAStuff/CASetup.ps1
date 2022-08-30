Install-WindowsFeature -Name AD-Certificate -ErrorAction Stop -IncludeManagementTools -IncludeAllSubFeature

Install-WindowsFeature GPMC | Out-Null
Install-WindowsFeature RSAT-AD-PowerShell | Out-Null
Install-WindowsFeature ADLDS -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null 

Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0

Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -ValidityPeriodUnits 20 -ValidityPeriod Years -CACommonName "Chris' Lab CA" -Confirm:$False
Install-AdcsWebEnrollment -Force | Out-Null

Get-CACrlDistributionPoint | Where-Object { $_.Uri -like "*://<ServerDNSName>/CertEnroll/<CAName><CRLNameSuffix><DeltaCRLAllowed>.crl" } | Remove-CACrlDistributionPoint -Confirm:$False | Out-Null
Add-CACrlDistributionPoint -Uri "http://<ServerDNSName>/CertEnroll/<CAName><CRLNameSuffix><DeltaCRLAllowed>.crl" -AddToCertificateCdp -AddToFreshestCrl -Confirm:$False | Out-Null

Get-CAAuthorityInformationAccess | Where-Object { $_.Uri -like "*://<ServerDNSName>/CertEnroll/*" } | Remove-CAAuthorityInformationAccess -Confirm:$False | Out-Null
Add-CAAuthorityInformationAccess -Uri "http://<ServerDNSName>/CertEnroll/<ServerDNSName>_<CAName><CertificateName>.crt" -AddToCertificateAia -Confirm:$False | Out-Null
Restart-Service "CertSvc"

## Create Workstation Authentication Certificate Template
Start-Process certutil.exe -ArgumentList "-dsAddTemplate $env:temp\WorkstationTemplate.txt" -NoNewWindow -Wait

$NewTemplate = "CN=Lab-WorkstationAuthentication,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$((Get-ADRootDSE).defaultNamingContext)"
Start-Process dsacls.exe -ArgumentList "`"$NewTemplate`" /g `"NT AUTHORITY\Authenticated Users`":CA;Enroll" -NoNewWindow -Wait -Verbose
Start-Process dsacls.exe -ArgumentList "`"$NewTemplate`" /g `"NT AUTHORITY\Authenticated Users`":CA;AutoEnrollment" -NoNewWindow -Wait
Restart-Service "CertSvc"

Add-CATemplate -Name "Lab-WorkstationAuthentication" -Confirm:$false

$GPO = New-GPO "Lab Certificate Enroll Policy"
Import-GPO -TargetGuid $GPO.Id -Path C:\users\KibbleC\Desktop\GPO -BackupId AFB81E8A-CE10-4ABA-8F0D-9F5543EA365C

New-GPLink -Guid $GPO.Id -Target $(Get-ADRootDSE).defaultNamingContext -ErrorAction Stop


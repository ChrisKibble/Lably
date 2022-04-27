# This needs to point to a valid ISO for Testing Lably
$env:LablyISO = 'C:\ISOs\en_windows_server_version_20h2_updated_jun_2021_x64_dvd_8ca193c2.iso'

Write-Host "Warning: If a test fails, it may leave behind Lably data, VM Switches, Network IPs, etc. that need to be manually cleaned up." -ForegroundColor Red

Start-Sleep -Seconds 5

Invoke-Pester -Path $PSScriptRoot

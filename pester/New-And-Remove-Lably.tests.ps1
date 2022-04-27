BeforeAll {
    $LablyModule = Join-Path $PSScriptRoot -ChildPath "..\Module\Lably.psd1"
    Import-Module $LablyModule -Force
}

Describe "New-Lably" {

    It "Build New Lably with Name Only" {
        $tmpFolder = "$($Env:temp)\tmp$([convert]::ToString((get-random 65535),16).PadLeft(4,'0')).tmp"
        
        New-Lably -Path $TmpFolder -Name "Pester Test"
        $jsonFile = Join-Path $tmpFolder -ChildPath "scaffold.lably.json"
        $virtualDiskPath = Join-Path $tmpFolder -ChildPath "Virtual Disks"
        $templateCachePath = Join-Path $tmpFolder -ChildPath "Template Cache"

        Test-Path $tmpFolder | Should -Be $true
        Test-Path $jsonFile | Should -Be $true
        Test-Path $virtualDiskPath | Should -Be $true
        Test-Path $templateCachePath | Should -Be $true
        
        $jsonData = Get-Content $jsonFile | ConvertFrom-Json
        $jsonData.Meta.Name | Should -Be "Pester Test"
        $jsonData.Meta.VirtualDiskPath | Should -Be $virtualDiskPath
        $jsonData.Meta.NATName | Should -BeNullOrEmpty
        $jsonData.Meta.NATIPCIDR | Should -BeNullOrEmpty

        $jsonData.Secrets.SecretType | Should -Be "PowerShell"

        $vmSwitchId = $jsonData.Meta.SwitchId

        $(Get-VMSwitch -Id $vmSwitchId -ErrorAction SilentlyContinue).Count | Should -Be 1 
    
        Remove-Lably -Path $tmpFolder -Confirm:$True
        Test-Path $tmpFolder | Should -Be $false
        $(Get-VMSwitch -Id $vmSwitchId -ErrorAction SilentlyContinue).Count | Should -Be 0 
    }

    It "Build New Lably with Existing Switch" {
        $tmpFolder = "$($Env:temp)\tmp$([convert]::ToString((get-random 65535),16).PadLeft(4,'0')).tmp"
        
        $TestSwitch = New-VMSwitch -Name ((Split-Path $tmpFolder -Leaf) -replace "\.","") -SwitchType Internal

        New-Lably -Path $TmpFolder -Name "Pester Test" -Switch $TestSwitch.Name
        $jsonFile = Join-Path $tmpFolder -ChildPath "scaffold.lably.json"
        $jsonData = Get-Content $jsonFile | ConvertFrom-Json

        $jsonData.Meta.NATName | Should -BeNullOrEmpty
        $jsonData.Meta.NATIPCIDR | Should -BeNullOrEmpty

        $vmSwitchId = $jsonData.Meta.SwitchId
        $vmSwitchId | Should -Be $TestSwitch.Id

        Remove-Lably -Path $tmpFolder -Confirm:$True

        $(Get-VMSwitch -Id $vmSwitchId -ErrorAction SilentlyContinue).Count | Should -Be 1 

        Get-VMSwitch -Id $vmSwitchId | Remove-VMSwitch -Force
    }

    It "Build New Lably with NAT" {

        # Need to find a test IP to use
        $ipList = Get-NetIPAddress | Select-Object -ExpandProperty IPv4Address

        ForEach($i in (0..254)) {
            $NetworkIPAddress = "169.254.$i.1"
            If(-Not($NetworkIPAddress -in $ipList)) {
                Break
            }
            If($i -eq 254) {
                Throw "Cannot find an IP Address to test with."
            }
        }

        $tmpFolder = "$($Env:temp)\tmp$([convert]::ToString((get-random 65535),16).PadLeft(4,'0')).tmp"

        New-Lably -Path $TmpFolder -Name "Pester Test" -NATIPAddress $NetworkIPAddress -NATRangeCIDR 1.1.1.0/24
        $jsonFile = Join-Path $tmpFolder -ChildPath "scaffold.lably.json"

        $jsonData = Get-Content $jsonFile | ConvertFrom-Json

        $jsonData.Meta.NATIPCIDR | Should -Be "1.1.1.0/24"

        @(Get-NetIPAddress -IPAddress $NetworkIPAddress -ErrorAction SilentlyContinue).Count | Should -Be 1
        @(Get-NetNat | Where-Object { $_.InternalIPInterfaceAddressPrefix -eq "1.1.1.0/24" }).Count | Should -Be 1

        Remove-Lably -Path $tmpFolder -Confirm:$True

        @(Get-NetIPAddress -IPAddress $NetworkIPAddress -ErrorAction SilentlyContinue).Count | Should -Be 0
        @(Get-NetNat | Where-Object { $_.InternalIPInterfaceAddressPrefix -eq "1.1.1.0/24" }).Count | Should -Be 0

    }

}

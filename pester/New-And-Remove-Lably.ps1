BeforeAll {
    $LablyModule = Join-Path $PSScriptRoot -ChildPath "..\Module\Lably.psd1"
    Import-Module $LablyModule -Force
}

Describe "New-Lably" {

    It "Build New Lably with Name Only" {
        $tmpFolder = "$($Env:temp)\tmp$([convert]::ToString((get-random 65535),16).PadLeft(4,'0')).tmp"
        Write-Host $TmpFolder
        
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
        Write-Host $TmpFolder
        
        $TestSwitch = New-VMSwitch -Name ((Split-Path $tmpFolder -Leaf) -replace "\.","") -SwitchType Internal
        Write-Output "Using Switch $($TestSwitch.Name)"

        New-Lably -Path $TmpFolder -Name "Pester Test" -Switch $TestSwitch.Name
        $jsonFile = Join-Path $tmpFolder -ChildPath "scaffold.lably.json"
        $jsonData = Get-Content $jsonFile | ConvertFrom-Json

        $jsonData.Meta.NATName | Should -BeNullOrEmpty
        $jsonData.Meta.NATIPCIDR | Should -BeNullOrEmpty

        $vmSwitchId = $jsonData.Meta.SwitchId
        $vmSwitchId | Should -Be $TestSwitch.Id

        Remove-Lably -Path $tmpFolder -Confirm:$True

        $(Get-VMSwitch -Id $vmSwitchId -ErrorAction SilentlyContinue).Count | Should -Be 1 
    }


}

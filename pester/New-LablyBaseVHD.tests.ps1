BeforeAll {
    $LablyModule = Join-Path $PSScriptRoot -ChildPath "..\Module\Lably.psd1"
    Import-Module $LablyModule -Force
    If(-Not($env:LablyISO)) {
        Write-Host "ERROR: You must define a LablyISO environment variable for the Get-LablyISODetails Test" -ForegroundColor Red
    }
}

Describe "New-LablyBaseVHD" {

    It "Create Base VHD" {
        
        $BaseVHDPath = "$($Env:temp)\tmp$([convert]::ToString((get-random 65535),16).PadLeft(4,'0')).vhdx"
        
        Try {
            New-LablyBaseVHD -ISO $env:LablyISO -VHD $BaseVHDPath
        } Catch {
            Throw "Failed to create new Base VHD"
        }

        Test-Path -Path $BaseVHDPath | Should -BeTrue

        Try {
            $mnt = Mount-VHD $BaseVHDPath -PassThru
        } Catch {
            Throw "Unable to mount VHDX"
        }

        $mnt.Path | Should -Be $BaseVHDPath
        @($mnt | Get-Disk).Count | Should -Be 1
        @($mnt | Get-Partition).Count | Should -BeGreaterOrEqual 3

        $OSDisk = $mnt | Get-Partition | Where-Object { $_.Type -eq "Basic" } | Sort-Object Size -Descending | Select-Object -First 1 -ExpandProperty DriveLetter

        $OSDisk | Should -Not -BeNullOrEmpty

        Test-Path -Path "$OSDisk`:\Windows" | Should -BeTrue

        $mnt | Dismount-VHD
        Remove-Item $BaseVHDPath -Force
    }

}

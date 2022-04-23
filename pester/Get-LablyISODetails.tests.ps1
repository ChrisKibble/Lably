BeforeAll {
    Import-Module ..\Module\Lably.psd1 -Force
    If(-Not($env:LablyISO)) {
        Write-Host "ERROR: You must define a LablyISO environment variable for the Get-LablyISODetails Test" -ForegroundColor Red
    }
}

Describe "Get-LablyISODetails" {
    It "Should return expected properties" {
        $ISODetails = Get-LablyISODetails -ISO $env:LablyISO | Select-Object -First 1
        $ModuleProperties = $ISODetails.PSObject.members | Where-Object { $_.MemberType -eq "Property" } | Select-Object -ExpandProperty Name

        $ModuleProperties | Should -Contain "ImagePath"
        $ModuleProperties | Should -Contain "ImageName"
        $ModuleProperties | Should -Contain "ImageIndex"
        $ModuleProperties | Should -Contain "ImageDescription"
        $ModuleProperties | Should -Contain "ImageSize"        
    }
}


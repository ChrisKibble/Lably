BeforeAll {
    $LablyModule = Join-Path $PSScriptRoot -ChildPath "..\Module\Lably.psd1"
    Import-Module $LablyModule -Force
    If(-Not($env:LablyISO)) {
        Write-Host "ERROR: You must define a LablyISO environment variable for the Get-LablyISODetails Test" -ForegroundColor Red
    }
}

Describe "Get-LablyISODetails" {

    BeforeAll {
        $ISODetails = Get-LablyISODetails -ISO $env:LablyISO | Select-Object -First 1
        $script:ModuleProperties = $ISODetails.PSObject.members | Where-Object { $_.MemberType -eq "Property" } | Select-Object -ExpandProperty Name
    }

    It "ISO Details Should Contain ImagePath" {
        $ModuleProperties | Should -Contain "ImagePath"
    }
    
    It "ISO Details Should Contain ImageName" {
        $ModuleProperties | Should -Contain "ImageName"
    }

    It "ISO Details Should Contain ImageIndex" {
        $ModuleProperties | Should -Contain "ImageDescription"
    }

    It "ISO Details Should Contain ImageDescription" {
        $ModuleProperties | Should -Contain "ImageDescription"
    }

    It "ISO Details Should Contain ImageSize" {
        $ModuleProperties | Should -Contain "ImageSize"        
    }
}


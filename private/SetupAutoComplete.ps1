$ThisModulePath = Split-Path $PSScriptRoot
$TemplatePath = Join-Path $ThisModulePath -ChildPath "Templates"

$scriptGetBaseImages = [scriptblock]::Create({

    param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst,$FakeBoundParameters )
 
    $BaseRegistry = "$env:userprofile\lably\BaseImageRegistry.json"

    If(-Not(Test-Path -Path $BaseRegistry -ErrorAction SilentlyContinue)) {
        Return $null
    }

    $Registry = Get-Content $BaseRegistry | ConvertFrom-Json

    $BaseList = ForEach($Image in $Registry.BaseImages) {
        If($Image.FriendlyName) {
            $Entry = $Image.FriendlyName
        } else {
            $Entry = $Image.ImagePath
        }
        If($Entry -like "* *") {
            $Entry = "`"$Entry`""
        }
        $Entry
    }

    Return @($BaseList)

})

$scriptGetVMDisplayNames = [scriptblock]::Create({

    param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst,$FakeBoundParameters )
 
    If($FakeBoundParameters.ContainsKey('Path')) {
        $Path = $FakeBoundParameters.Path
    } else {
        $Path = $PWD
    }

    $ScaffoldPath = Join-Path $Path -ChildPath "scaffold.lably.json" -ErrorAction SilentlyContinue

    If(-Not($ScaffoldPath)) { Return $null }
    If(-Not(Test-Path $ScaffoldPath -ErrorAction SilentlyContinue)) { Return $null}

    Try {
        $(Get-Content $ScaffoldPath | ConvertFrom-Json).Assets.DisplayName | ForEach-Object {
            If($_ -like "* *") {
                "`"$_`""
            } else {
                $_
            }
        }
    } Catch {
        Return $null
    }

})

$scriptGetTemplateNames = [scriptblock]::Create({

    param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )

    $Templates = @(Get-ChildItem -Path $Script:TemplatePath -Filter "*.json")
    $Templates += @(Get-ChildItem -Path (Join-Path $env:USERPROFILE -ChildPath "Lably\Templates") -Filter "*.json")

    $Templates = $Templates | Select-Object -ExpandProperty BaseName | Sort-Object -Unique

    $Templates = $Templates | ForEach-Object {
        If($_ -like "* *") {
            "`"$_`""
        } else {
            $_
        }
    }

    Return @($Templates)

}).GetNewClosure()

$scriptGetSwitchName = [scriptblock]::Create({

    param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )

    $Switches = Get-VMSwitch | Select-Object -ExpandProperty Name

    $Switches = $Switches | ForEach-Object {
        If($_ -like "* *") {
            "`"$_`""
        } else {
            $_
        }
    }

    Return @($Switches)

})


Register-ArgumentCompleter -CommandName New-LablyVM -ParameterName Template -ScriptBlock $scriptGetTemplateNames
Register-ArgumentCompleter -CommandName New-LablyVM -ParameterName BaseVHD -ScriptBlock $scriptGetBaseImages
Register-ArgumentCompleter -CommandName Remove-LablyVM -ParameterName DisplayName -ScriptBlock $scriptGetVMDisplayNames
Register-ArgumentCompleter -CommandName New-Lably -ParameterName "Switch" -ScriptBlock $scriptGetSwitchName 

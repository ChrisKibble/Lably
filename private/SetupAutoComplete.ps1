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

Register-ArgumentCompleter -CommandName New-LablyVM -ParameterName BaseVHD -ScriptBlock $scriptGetBaseImages
Register-ArgumentCompleter -CommandName Remove-LablyVM -ParameterName DisplayName -ScriptBlock $scriptGetVMDisplayNames

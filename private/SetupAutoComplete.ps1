$ScriptBlock = [scriptblock]::Create({

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

Register-ArgumentCompleter -CommandName New-LablyVM -ParameterName BaseVHD -ScriptBlock $ScriptBlock
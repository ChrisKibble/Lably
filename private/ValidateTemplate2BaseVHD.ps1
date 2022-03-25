
Function ValidateTemplate2BaseVHD {

    [CmdLetBinding()]
    Param(
        $LablyTemplate,
        $RegistryEntry,
        $HostnameDefined
    )

    Write-Verbose "Validating Template Requirements"
    
    $AllRequirementsValid = $True

    ForEach($BaseVHDRequirement in $LablyTemplate.Requirements.BaseVHD | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) {
        
        Write-Verbose "... Validating $BaseVHDRequirement"
        $ValidatedRequirement = $False

        ForEach($Req in $LablyTemplate.Requirements.BaseVHD.$BaseVHDRequirement) {
            If($RegistryEntry.$BaseVHDRequirement -like "$Req") {
                Write-Verbose "...... $($RegistryEntry.$BaseVHDRequirement) is like $($Req)."
                $ValidatedRequirement = $True
            }
        }

        If(-Not($ValidatedRequirement)) {
            $AllRequirementsValid = $False
            Write-Warning "Template Requires BaseVHD $BaseVHDRequirement one of: [$($LablyTemplate.Requirements.BaseVHD.$BaseVHDRequirement -join ",")]"
        }

    }

    If($LablyTemplate.Requirements.DenyDefaultHostname -and $HostnameDefined -eq $False) {
        Write-Warning "This template requires you to set an explicit hostname."
        $AllRequirementsValid = $False
    }

    Return $AllRequirementsValid

}

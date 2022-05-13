Function Reset-Lably {

    <#
    
    .SYNOPSIS

    Deletes and recreates an existing Lably. All data will be destroyed.

    .DESCRIPTION

    This function is used to delete and recreate a new Lably. 

    .PARAMETER Path
    
    Optional parameter to define where the lably will be created. The scaffold, template cache, and (optionally) virtual disks folders will be created within this folder. If this parameter is not defined, it will default to the path from which the function was called.

    .PARAMETER Confirm

    Optional Switch to bypass confirming that you want to delete the Lab and associated data.

    .INPUTS

    None. You cannot pipe objects to New-Lably.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    Reset-Lably

    #>

    [CmdLetBinding(DefaultParameterSetName='NewSwitch')]
    Param(
        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD,

        [Parameter(Mandatory=$False)]
        [Switch]$Confirm
    )

    ValidateModuleRun -RequiresAdministrator

    $LablyScaffold = Join-Path $Path -ChildPath "scaffold.lably.json"
    Write-Verbose "Reading Lably Scaffolding File at $LablyScaffold"

    If(-Not(Test-Path $LablyScaffold -ErrorAction SilentlyContinue)){
        Throw "There is no Lably at $Path."
    }

    Try {
        $Scaffold = Get-Content $LablyScaffold | ConvertFrom-Json
    } Catch {
        Throw "Unable to import Lably scaffold. $($_.Exception.Message)"
    }

    If(-Not($Confirm)) {
        Write-Host "WARNING! Resetting your Lably will delete ALL DATA ON YOUR VMs!" -ForegroundColor Red
        Write-Host "This operation cannot be undone." -ForegroundColor Red
        Write-Host ""
        If($(Read-Host "If you're certain you'd like to continue, type RESET and press enter") -ne "RESET") {
            Write-Host "Code 'RESET' was not entered. Aborting." -ForegroundColor Yellow
            Return
        }
    }

    $Assets = $Scaffold.Assets

    # Validate that All Assets with Template GUIDs are cached

    $TemplateCache = Join-Path $Path -ChildPath "Template Cache"
    $TemplatesValid = $True

    ForEach($Template in $Assets.TemplateGuid | Select-Object -Unique) {
        $TemplateFile = Join-Path $TemplateCache -ChildPath "$Template.json"
        If(-Not(Test-Path $TemplateFile -ErrorAction SilentlyContinue)) {
            Write-Host "Error: Cannot find cached template $Template"
            $TemplatesValid = $False
        }
    }

    If(-Not($TemplatesValid)) {
        Throw "Missing templates in cache to rebuild Lably."
    }

    ForEach($Asset in $Assets) {
        Write-Host "Removing $($Asset.DisplayName)"
        Remove-LablyVM -Path $Path -VMId $Asset.VMId -Confirm | Out-Null
    }

    ForEach($Asset in $Assets) {
        [System.Collections.Hashtable]$TemplateAnswers = @{}
        
        If($asset.InputResponse) {
            
            $Asset.InputResponse | Where-Object { $_.Secure -eq $True } | ForEach-Object {
                # Because template answers normally come from the user, we need to use a normal secure string and not one that uses our secret.
                $_.Val = $(Get-DecryptedString -EncryptedText $_.val -SecretType $Scaffold.Secrets.SecretType -SecretKeyFile $Scaffold.Secrets.KeyFile) | ConvertTo-SecureString -AsPlainText -Force
            }

            $asset.InputResponse | ForEach-Object {
                $TemplateAnswers.Add($_.Name,$_.Val)
            }    
        }
        
        [System.Collections.HashTable]$LablyVM = @{
            DisplayName = $Asset.DisplayName
            BaseVHD = $Asset.BaseVHD
            AdminPassword = $(Get-DecryptedString -EncryptedText $asset.AdminPassword -SecretType $scaffold.Secrets.SecretType -SecretKeyFile $Scaffold.Secrets.KeyFile | ConvertTo-SecureString -AsPlainText -Force)
            Hostname = $Asset.Hostname
            ProductKey = $Asset.ProductKey
            Timezone = $Asset.Timezone
            Locale = $Asset.Locale
            MemoryMinimumInBytes = $Asset.Hardware.MemoryMinimumInBytes
            MemoryMaximumInBytes = $Asset.Hardware.MemoryMaximumInBytes
            MemorySizeInBytes = $Asset.Hardware.MemorySizeInBytes
            CPUCount = $Asset.Hardware.CPUCount
        }

        If($Asset.TemplateGuid) {
            $TemplatePath = Join-Path $TemplateCache -ChildPath "$($Asset.TemplateGuid).json"
            $LablyVM.Add("Template", $TemplatePath)
            $LablyVM.Add("TemplateAnswers", $TemplateAnswers)
        }

        New-LablyVM @LablyVM
    }


}
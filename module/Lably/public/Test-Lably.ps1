Function Test-Lably {
    
    <#
    
    .SYNOPSIS

    Tests the Lably Scaffold for Inconsistencies.

    .DESCRIPTION

    This function is used to test your Lably scaffold against your file system and Hyper-V to ensure consistency.

    .PARAMETER Path
    
    Optional parameter to define where the lably is stored. If this parameter is not defined, it will default to the path from which the function was called.

    .PARAMETER Fix
    
    Switch to resolve issues with if found.

    .INPUTS

    None. You cannot pipe objects to Test-Lably.

    .OUTPUTS

    None. The function will either complete successfully or throw an error.
    
    .EXAMPLE

    Test-Lably

    .EXAMPLE

    Test-Lably -Fix
    
    #>

    [CmdLetBinding()]
    Param(

        [Parameter(Mandatory=$False)]
        [String]$Path = $PWD,

        [Parameter(Mandatory=$False)]
        [Switch]$Fix
    )

    ValidateModuleRun -RequiresAdministrator

    $LablyScaffold = Join-Path $Path -ChildPath "scaffold.lably.json"
    $Scaffold = Import-LablyScaffold -LablyScaffold $LablyScaffold -ErrorAction Stop

    $FixApplied = $False

    Write-Host "Verifying Switch." -NoNewline
    If($Scaffold.Meta.SwitchId) {
        Try {
            $Switch = Get-VMSwitch -id $Scaffold.Meta.SwitchId -ErrorAction Stop
            If($Switch) {
                Write-Host " Found '$($Switch.Name)'." -NoNewline
                Write-Host " Success." -ForegroundColor Green    
            } Else { 
                Write-Host "Failed. No such Switch in Hyper-V." -ForegroundColor Red
            }
        } Catch {
            Write-Host "Failed. Unable to query for Switch. $($_.Exception.Message)." -ForegroundColor Red
        }
    } Else {
        Write-Host " No Switch Exists for Lably." -ForegroundColor Gray
    }

    If($Scaffold.Meta.NATIPCIDR) {
        Write-Host "Verifying NAT IP $($Scaffold.Meta.NATIPCIDR)." -NoNewline
        Try {
            $NAT = Get-NetNat -ErrorAction SilentlyContinue | Where-Object { $_.InternalIPInterfaceAddressPrefix -eq $Scaffold.Meta.NATIPCIDR }
            If($NAT) {
                Write-Host " Found '$($NAT.Name)'." -NoNewline
                Write-Host " Success." -ForegroundColor Green    
            } Else { 
                Write-Host "Failed. No such Switch in Hyper-V." -ForegroundColor Red
            }
        } Catch {
            Write-Host "Failed. Unable to query for Switch. $($_.Exception.Message)." -ForegroundColor Red
        }
    }

    Write-Host "Verifying Secrets." -NoNewline
    If($Scaffold.Secrets.SecretType -eq "PowerShell") {
        Write-Host " Secret Type is PowerShell." -NoNewline
        Write-Host " Success." -ForegroundColor Green
    } ElseIf ($Scaffold.Secrets.SecretType -eq "KeyFile") {
        Write-Host " Secret Type is KeyFile." -NoNewline
        If(-Not($Scaffold.Secrets.KeyFile)) {
            Write-Host " No KeyFile Defined." -NoNewline
            Write-Host " Failed." -ErrorAction SilentlyContinue
        } ElseIf(-Not(Test-Path $Scaffold.Secrets.KeyFile -ErrorAction SilentlyContinue)) {
            Write-Host " File is missing ($($Scaffold.Secrets.KeyFile))." -NoNewline
            Write-Host " Failed." -ForegroundColor Red
        } Else {
            Try {
                $secret = "secret" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key (Get-Content $Scaffold.Secrets.KeyFile) -ErrorAction Stop
                $ssSecret = $secret | ConvertTo-SecureString -Key (Get-Content $Scaffold.Secrets.KeyFile) -ErrorAction Stop
                $plainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ssSecret))
                If($plainSecret -eq "secret") {
                    Write-Host " Success." -ForegroundColor Green
                } Else {
                    Write-Host " Secret could not be decrypted." -NoNewline
                    Write-Host " Failed." -ForegroundColor Red
                }
            } Catch {
                Write-Host $_.Exception.Message -NoNewline
                Write-Host " Failed." -ForegroundColor Red
            }
        }
    }

    ForEach($Asset in $Scaffold.Assets) {
        Write-Host "Verifying '$($Asset.DisplayName)'"
        Try {
            Write-Host "   Checking Hyper-V for VM." -NoNewLine
            $VM = Get-VM -Id $Asset.VMId
            Write-Host " Success." -ForegroundColor Green
            Write-Host "   Checking Display Name." -NoNewline
            If($VM.Name -ne $Asset.DisplayName) {
                If(-Not($Fix)) {
                    Write-Host " Display Name: $($VM.Name)." -NoNewline
                    Write-Host " Failed." -ForegroundColor Red
                } Else {
                    Write-Host " Display Name: $($VM.Name)." -NoNewline
                    $Asset.DisplayName = $VM.Name
                    $FixApplied = $True
                    Write-Host " Fixed." -ForegroundColor Yellow                    
                }
            } Else {
                Write-Host " Success." -ForegroundColor Green
            }
        } Catch {
            Write-Host " Error: $($_.Exception.Message)" -NoNewline
            Write-Host " Failed." -ForegroundColor Red
        }
    }

    If($Fix -and $FixApplied) {
        Try {
            Write-Host "Updating Scaffold"
            $Scaffold | ConvertTo-Json -Depth 100 | Out-File $LablyScaffold -Force
        } Catch {
            Write-Warning "Unable to Update Lably Scaffold."
            Write-Warning $_.Exception.Message
        }    
    }
}
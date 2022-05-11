Function Get-EncryptedString {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$PlainText,

        [Parameter(Mandatory=$False)]
        [ValidateSet("PowerShell","KeyFile")]
        [String]$SecretType = "PowerShell",

        [Parameter(Mandatory=$False)]
        [String]$SecretKeyFile
    )

    If($SecretType -eq "KeyFile" -and -not $SecretKeyFile) {
        Throw "KeyFile must be defined."
    }

    If($SecretType -eq "KeyFile") {
        Try {
            $SecretsKey = [Byte[]](Get-Content $SecretKeyFile -ErrorAction Stop)
        } Catch {
            Throw "Unable to load Secret Key File: $($_.Exception.Message)"
        }
    }
    
    Try {
        $SecureString = $PlainText | ConvertTo-SecureString -AsPlainText -Force
        If($SecretType -eq "PowerShell") {
            $EncryptedText = $SecureString | ConvertFrom-SecureString
        } elseif($SecretType -eq "KeyFile") {
            $EncryptedText = $SecureString | ConvertFrom-SecureString -Key $SecretsKey
        }
    } Catch {
        Throw "Could not encrypt secret. $($_.Exception.Message)"
    }

    Return $EncryptedText
 
}
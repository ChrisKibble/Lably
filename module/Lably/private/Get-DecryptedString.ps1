Function Get-DecryptedString {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        $EncryptedText,

        [Parameter(Mandatory=$False)]
        [ValidateSet("PowerShell","KeyFile")]
        [String]$SecretType = "PowerShell",

        [Parameter(Mandatory=$False)]
        [String]$SecretKeyFile
    )

    If($SecretType -eq "KeyFile" -and -not $SecretKeyFile) {
        Throw "KeyFile must be defined."
    }

    If($EncryptedText -is [SecureString]) {
        [String]$EncryptedText = $EncryptedText | ConvertFrom-SecureString
    }

    If($SecretType -eq "KeyFile") {
        Try {
            $SecretsKey = [Byte[]](Get-Content $SecretKeyFile -ErrorAction Stop)
        } Catch {
            Throw "Unable to load Secret Key File: $($_.Exception.Message)"
        }
    }
    
    Try {
        If($SecretType -eq "PowerShell") {
            $SecureString = $EncryptedText | ConvertTo-SecureString
        } elseif($SecretType -eq "KeyFile") {
            $SecureString = $EncryptedText | ConvertTo-SecureString -Key $SecretsKey
        }
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    } Catch {
        Throw "Could not decrypt secret. $($_.Exception.Message)"
    }

    Return $PlainText
 
}
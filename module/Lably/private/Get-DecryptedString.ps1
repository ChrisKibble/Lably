Function Get-DecryptedString {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$EncryptedText,

        [Parameter(Mandatory=$False)]
        [ValidateSet("PowerShell","SecretKey")]
        [String]$SecretType = "PowerShell",

        [Parameter(Mandatory=$False)]
        [String]$SecretKeyFile
    )

    If($SecretType -eq "SecretKey" -and -not $SecretKeyFile) {
        Throw "KeyFile must be defined."
    }

    If($SecretType -eq "SecretKey") {
        Try {
            $SecretsKey = [Byte[]](Get-Content $SecretKeyFile -ErrorAction Stop)
        } Catch {
            Throw "Unable to load Secret Key File: $($_.Exception.Message)"
        }
    }
    
    Try {
        If($SecretType -eq "PowerShell") {
            $SecureString = $EncryptedText | ConvertTo-SecureString
        } elseif($SecretType -eq "SecretKey") {
            $SecureString = $EncryptedText | ConvertTo-SecureString -Key $SecretsKey
        }
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    } Catch {
        Throw "Could not decrypt secret. $($_.Exception.Message)"
    }

    Return $PlainText
 
}
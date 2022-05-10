Function Get-DateUTC {

    Param(
        [Parameter(Mandatory=$False)]
        [DateTime]$DateTime = $(Get-Date)
    )
    
    Return $DateTime.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")

}
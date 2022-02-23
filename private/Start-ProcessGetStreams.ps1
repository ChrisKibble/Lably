Function Start-ProcessGetStreams {
    [CmdLetBinding()]
    Param(
        [System.IO.FileInfo]$FilePath,
        [string[]]$ArgumentList
    )

    $pInfo = New-Object System.Diagnostics.ProcessStartInfo
    $pInfo.FileName = $FilePath
    $pInfo.Arguments = $ArgumentList
    $pInfo.RedirectStandardError = $true
    $pInfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pInfo.CreateNoWindow = $true
    $pInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $pInfo

    Try {
        Write-Verbose "Starting $FilePath"
        $proc.Start() | Out-Null
    } Catch {
        Throw "Unable to Start Process. $($_.Exception.Message)"
    }
    
    Write-Verbose "Waiting for $($FilePath.BaseName) to complete"
    $proc.WaitForExit()

    Try {
        $stdOut = $proc.StandardOutput.ReadToEnd()
        $stdErr = $proc.StandardError.ReadToEnd()
        $exitCode = $proc.ExitCode
    } Catch {
        Throw "Unable to Read Process Streams or Exit Code $($_.Exception.Message)"
    }

    [PSCustomObject]@{
        "StdOut" = $stdOut
        "Stderr" = $stdErr
        "ExitCode" = $exitCode
    }
}

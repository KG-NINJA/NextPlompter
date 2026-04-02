param(
    [int]$IdleSeconds = 180,
    [string]$WindowTitlePattern = 'Codex',
    [string]$Message = 'next',
    [int]$PollSeconds = 5,
    [int]$MaxIterations = 0,
    [int]$MaxLoops = 0,
    [string]$StopFile = '.\stop.keep-codex-going'
)

Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class IdleTime {
    [StructLayout(LayoutKind.Sequential)]
    private struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static uint GetIdleMilliseconds() {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(lii);
        GetLastInputInfo(ref lii);
        return unchecked((uint)Environment.TickCount - lii.dwTime);
    }
}
"@

$script:SentCount = 0
$script:LoopCount = 0

function Get-IdleSeconds {
    [math]::Floor(([IdleTime]::GetIdleMilliseconds()) / 1000)
}

function Test-StopRequested {
    if (Test-Path -LiteralPath $StopFile) {
        Write-Host ("[{0}] stop file detected: {1}" -f (Get-Date), $StopFile)
        return $true
    }

    try {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -in @('Q', 'Escape')) {
                Write-Host ("[{0}] stop key pressed: {1}" -f (Get-Date), $key.Key)
                return $true
            }
        }
    }
    catch {
        return $false
    }

    return $false
}

function Wait-Interruptibly {
    param(
        [int]$Seconds
    )

    for ($i = 0; $i -lt $Seconds * 10; $i++) {
        if (Test-StopRequested) {
            return $true
        }
        Start-Sleep -Milliseconds 100
    }

    return $false
}

function Set-ClipboardText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    Set-Clipboard -Value $Text
}

Write-Host "Press q or Esc to stop."
Write-Host "Creating $StopFile also stops the loop."
Write-Host ("IdleSeconds={0}, PollSeconds={1}, WindowTitlePattern='{2}', Message='{3}'" -f $IdleSeconds, $PollSeconds, $WindowTitlePattern, $Message)

try {
    while ($true) {
        $script:LoopCount++

        if ($MaxLoops -gt 0 -and $script:LoopCount -gt $MaxLoops) {
            break
        }

        if ($MaxIterations -gt 0 -and $script:SentCount -ge $MaxIterations) {
            break
        }

        if (Test-StopRequested) {
            break
        }

        $idle = Get-IdleSeconds
        $activeTitle = (Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -match $WindowTitlePattern } | Select-Object -First 1).MainWindowTitle

        if ($idle -ge $IdleSeconds -and $activeTitle) {
            Set-ClipboardText -Text $Message
            $script:SentCount++
            Write-Host ("[{0}] copied '{2}' to clipboard for '{1}' ({3}); press Enter to send" -f (Get-Date), $activeTitle, $Message, $script:SentCount)

            if (Wait-Interruptibly -Seconds $IdleSeconds) {
                break
            }
        }

        if (Wait-Interruptibly -Seconds $PollSeconds) {
            break
        }
    }
}
finally {
    Write-Host ("[{0}] stopped. sent={1}, loops={2}" -f (Get-Date), $script:SentCount, $script:LoopCount)
}

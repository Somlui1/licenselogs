# Requires -Version 5.1 or later
# Requires ImportExcel module: Install-Module -Name ImportExcel
$logFile = "sw_log.txt"
# Regex patterns
$timestampPattern = 'TIMESTAMP (\d{1,2}/\d{1,2}/\d{4})'
$entryPattern = '(\d{1,2}:\d{2}:\d{2}) \(SW_D\) (OUT|IN|DENIED|UNSUPPORTED): "([^"]+)" ([\w.]+)@([\w\d]+)'

$data = @()
$currentDate = $null

Get-Content $logFile -Encoding utf8 | ForEach-Object {
    $line = $_

    # Check if line contains timestamp
    if ($line -match $timestampPattern) {
        $currentDate = $matches[1]
        return
    }

    # Check if line matches entry pattern and currentDate is set
    if ($currentDate -and $line -match $entryPattern) {
        $timeStr = $matches[1]
        $status = $matches[2]
        $feature = $matches[3]
        $user = $matches[4]
        $computer = $matches[5]

        $fullDateTimeStr = "$currentDate $timeStr"
        # Parse datetime using invariant culture and en-US format (MM/dd/yyyy)
        $dt = [datetime]::ParseExact($fullDateTimeStr, "M/d/yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)

        $data += [PSCustomObject]@{
            datetime = $dt
            status = $status
            feature = $feature
            user = $user
            computer = $computer
        }
    }
}

# Match OUT and IN sessions
$outSessions = @{}
$sessions = @()

foreach ($row in $data) {
    $key = "$($row.feature)|$($row.user)|$($row.computer)"
    if ($row.status -eq 'OUT') {
        $outSessions[$key] = $row
    }
    elseif ($row.status -eq 'IN') {
        if ($outSessions.ContainsKey($key)) {
            $start = $outSessions[$key]
            $outSessions.Remove($key)
            $end = $row

            $durationSec = ($end.datetime - $start.datetime).TotalSeconds
            if ($durationSec -lt 0) {
                # Skip invalid time records
                continue
            }

            $sessions += [PSCustomObject]@{
                start_date = $start.datetime.ToString("yyyy-MM-dd")
                start_time = $start.datetime.ToString("HH:mm:ss")
                end_date = $end.datetime.ToString("yyyy-MM-dd")
                end_time = $end.datetime.ToString("HH:mm:ss")
                duration_minutes = [math]::Round($durationSec / 60, 2)
                feature = $start.feature
                username = $start.user
                computer = $start.computer
            }
        }
    }
}

# Export to Excel (requires ImportExcel module)
$sessions | Export-Excel -Path "sw_log_sessions.xlsx" -AutoSize -WorksheetName "Sessions"
Write-Host "Session summary exported to sw_log_sessions.xlsx"
# Show first 5 sessions
$sessions | Select-Object -First 5 | Format-Table -AutoSize

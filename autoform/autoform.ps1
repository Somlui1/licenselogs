$user = "aapico\itsupport"
$pass = ConvertTo-SecureString "support" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
# ดึง log ไฟล์จาก remote server
$logfile = Invoke-Command -ComputerName 10.10.3.10 -Credential $cred -ScriptBlock {
    $logDir = "C:\Users\ahroot\Documents"
    # Find all files matching pattern
    $logFiles = Get-ChildItem -Path $logDir -Filter "Logfile.rlog.*" -File -Recurse
    # Initialize array for content
    $combined = @()

    foreach ($file in $logFiles) {
        try {
            $lines = Get-Content $file.FullName -ErrorAction Stop
            $combined += $lines
        } catch {
            Write-Warning "Failed to read file: $($file.FullName)"
        }
    }
    # Return combined content to the caller
    return $combined
}
# Check if log was retrieved
if (-not $logfile) {
    Write-Error "No log data retrieved."
    return
}
# เตรียมตัวแปร
$outEntries = @{}
$sessions   = @()
# ประมวลผลบรรทัดละบรรทัด
$logfile | ForEach-Object {
    $line = $_.Trim()
    $parts = $line -split '\s+'

    if ($parts.Count -lt 10) {
        return
    }
    $action = $parts[0].ToUpper()
    if ($action -eq 'OUT') {
        $module    = $parts[1]
        $version   = $parts[2]
        $hostName  = $parts[4]
        $user      = $parts[5]
        $license_id = $parts[10]
        $date = $parts[-2]
        $time = $parts[-1]
        $datetime_str = "2025-$date $time"

        try {
            $start_dt = [datetime]::ParseExact($datetime_str, "yyyy-MM/dd HH:mm:ss", $null)
        } catch {
            return
        }

        $outEntries[$license_id] = [pscustomobject]@{
            module        = $module
            version       = $version
            host          = $hostName
            user          = $user
            start_datetime = $start_dt
            start_date    = $start_dt.ToString("yyyy-MM-dd")
            start_time    = $start_dt.ToString("HH:mm:ss")
            start_hours   = $start_dt.ToString("HH")
            start_action  = $action
        }
    }

    elseif ($action -eq 'IN') {
        $license_id = $parts[-3]
        $date = $parts[-2]
        $time = $parts[-1]
        $datetime_str = "2025-$date $time"

        try {
            $end_dt = [datetime]::ParseExact($datetime_str, "yyyy-MM/dd HH:mm:ss", $null)
        } catch {
            return
        }

        if ($outEntries.ContainsKey($license_id)) {
            $entry = $outEntries[$license_id]
            $duration = ($end_dt - $entry.start_datetime).TotalMinutes

            $session = [pscustomobject]@{
                start_date       = $entry.start_date
                start_time       = $entry.start_time
                start_hours      = $entry.start_hours
                start_action     = $entry.start_action
                end_date         = $end_dt.ToString("yyyy-MM-dd")
                end_time         = $end_dt.ToString("HH:mm:ss")
                end_hours        = $end_dt.ToString("HH")
                end_action       = $action
                duration_minutes = [math]::Round($duration, 2)
                host             = $entry.host
                module           = $entry.module
                user             = $entry.user
                version          = $entry.version
            }

            $sessions += $session
            $outEntries.Remove($license_id)
        }
    }
}
# แสดงผลลัพธ์ในตาราง
$sessions | Format-Table -AutoSize
# Export sessions to Excel
$excelPath = "C:\sessions.xlsx"
$sessions | Export-Excel -Path $excelPath -AutoSize -WorksheetName 'Sessions' -TableName 'SessionData'
Write-Host "Exported sessions to $excelPath"
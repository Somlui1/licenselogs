# ต้องติดตั้ง ImportExcel module ก่อน
# Install-Module -Name ImportExcel -Scope CurrentUser

$log_file = "license_log.txt"
$sessions = @()
$out_entries = @{}
$current_date = $null
$last_datetime = $null

function Parse-DateFromStartDate($line) {
    if ($line -match '\d{2}:\d{2}:\d{2} \(lmgrd\) \(@lmgrd-SLOG@\) Start-Date: (.+)') {
        $raw_date = $matches[1].Trim() -replace " SE Asia",""
        return [datetime]::ParseExact($raw_date, "ddd MMM dd yyyy HH:mm:ss", $null).Date
    }
    return $null
}

# อ่าน log file
$lines = Get-Content $log_file -Encoding UTF8

foreach ($line in $lines) {
    # อัปเดตวันที่เมื่อเจอ Start-Date ใหม่
    $new_date = Parse-DateFromStartDate $line
    if ($new_date) {
        $current_date = $new_date
        continue
    }

    # จับ log OUT / IN
    if ($line -match '^(\d{2}:\d{2}:\d{2}) \(saltd\) (OUT|IN): "([^"]+)" ([^@]+)@(.+)$' -and $current_date) {
        $time_str = $matches[1]
        $action = $matches[2]
        $module = $matches[3]
        $user = $matches[4]
        $host = $matches[5]

        $time_obj = [datetime]::ParseExact($time_str, "HH:mm:ss", $null).TimeOfDay

        # ตรวจสอบข้ามวัน
        if ($last_datetime -and $time_obj -lt $last_datetime.TimeOfDay) {
            $current_date = $current_date.AddDays(1)
        }

        $dt = [datetime]::ParseExact(($current_date.ToString("yyyy-MM-dd") + " " + $time_str), "yyyy-MM-dd HH:mm:ss", $null)
        $last_datetime = $dt

        $key = "$user|$host|$module"

        if ($action -eq "OUT") {
            $out_entries[$key] = @{
                start_datetime = $dt
                start_date = $dt.ToString("yyyy-MM-dd")
                start_time = $dt.ToString("HH:mm:ss")
                user = $user
                host = $host
                module = $module
            }
        } elseif ($action -eq "IN") {
            if ($out_entries.ContainsKey($key)) {
                $start = $out_entries[$key]
                $out_entries.Remove($key)
                $duration_minutes = [math]::Round(($dt - $start.start_datetime).TotalMinutes, 2)
                $sessions += [PSCustomObject]@{
                    start_date = $start.start_date
                    start_time = $start.start_time
                    end_date = $dt.ToString("yyyy-MM-dd")
                    end_time = $dt.ToString("HH:mm:ss")
                    duration_minutes = $duration_minutes
                    host = $host
                    module = $module
                    user = $user
                }
            }
        }
    }
}

# ส่งออก Excel
$sessions | Export-Excel -Path "license_sessions_multiday.xlsx" -AutoSize

# แสดงผล
$sessions | Format-Table -AutoSize

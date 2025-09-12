Set-Location $PSScriptRoot
. .\function.ps1

# 2️⃣ ประมวลผลข้อมูล IN/OUT
$outEntries = @{}
$sessions = @()
$year = get-date -Format "yyyy"
$logfile | ForEach-Object {
    $line = $_.Trim()
    $parts = $line -split '\s+'
    if ($parts.Count -lt 10) { return }
    $action = $parts[0].ToUpper()
    if ($action -eq 'OUT') {
        $module    = $parts[1]
        $version   = $parts[2]
        $username  = $parts[4]
        $hostName  = $parts[5]
        $hash      = $parts[6]
        $license_id = $parts[10]
        $date = $parts[-2]
        $time = $parts[-1]
        $datetime_str = "$year-$date $time"
        $keyword = "$module|$hash|$username|$hostName"
        try {
            $start_dt = [datetime]::ParseExact($datetime_str, "yyyy-MM/dd HH:mm:ss", $null)
        } catch {
            return
        }
        $outEntries[$keyword] = [PSCustomObject]@{
            module         = $module
            version        = $version
            host           = $hostName
            username       = $username
            start_action   = $action
            start_datetime = $start_dt
            hash           = $hash
            license_id     = $license_id
        }
    }
    elseif ($action -eq 'IN') {
        $module   = $parts[2]  # ปรับ index ให้ตรง module ของ IN
        $hash     = $parts[6]  # ปรับ index ให้ตรง hash ของ IN
        $license_id = $parts[10]
        $keyword = "$module|$hash|$username|$hostName"
        $date = $parts[-2]
        $time = $parts[-1]
        $datetime_str = "$year-$date $time"

        try {
            $end_dt = [datetime]::ParseExact($datetime_str, "yyyy-MM/dd HH:mm:ss", $null)
        } catch {
            return
        }
        if ($outEntries.ContainsKey($keyword)) {
            $entry = $outEntries[$keyword]
            $duration = ($end_dt - $entry.start_datetime).TotalMinutes
            $session = [PSCustomObject]@{
                start_datetime   = $entry.start_datetime.ToString("yyyy-MM-dd HH:mm:ss")
                start_action     = $entry.start_action
                end_datetime     = $end_dt.ToString("yyyy-MM-dd HH:mm:ss")
                end_action       = $action
                duration_minutes = [math]::Round($duration, 2)
                host             = $entry.host
                module           = $entry.module
                username         = $entry.username
                version          = $entry.version
                hash_id          = "$($hash.Trim('"'))$((Get-Date).ToString('MMyy'))"
                license_id       = $entry.license_id
            }
            $sessions += $session
            $outEntries.Remove($keyword)
        }
    }
}
      #session = [PSCustomObject]@{
      #         start_datetime    = $entry.start_date
      #         start_action     = $entry.start_action
      #         end_datetime      = $end_dt.ToString("yyyy-MM-dd")
      #         end_action       = $action
      #         duration_minutes = [math]::Round($duration, 2)
      #         host             = $entry.host
      #         module           = $entry.module
      #         username         = $entry.username
      #         version          = $entry.version
      #         hash_id          = $entry.hash_id
      #         license_id       = $entry.license_id
      #     }      

Write-Host -ForegroundColor Cyan "Total sessions: $($sessions.Count)"
exit -1
$payloadChunks = Split-ToChunks -InputArray $sessions -ChunkSize 1200
foreach ($chunk in $payloadChunks) {
    $payload = @{
        ip = 0
        product = "autoform"
        data = @($chunk)
    }
    $targetUrl = "http://localhost/testing/"
    $response = Send-JsonPayload -Url $targetUrl -Payload $payload -depth 10
    Write-Host "Response from server: $response"

    Start-Sleep -Seconds 2
}

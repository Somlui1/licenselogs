$user = "aapico\itsupport"
$pass = ConvertTo-SecureString "support" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

# 1️⃣ ดึงไฟล์จาก Remote Server
$logfile = Invoke-Command -ComputerName 'AITS25A1PC0040.aapico.com' -Credential $cred -ScriptBlock {
    $logDir = "C:\Users\ahroot\Documents"
    $logFiles = Get-ChildItem -Path $logDir -Filter "Logfile.rlog.2025.*" -File -Recurse
    $combined = @()

    foreach ($file in $logFiles) {
        try {
            $lines = Get-Content $file.FullName -ErrorAction Stop
            $combined += $lines
        } catch {
            Write-Warning "Failed to read file: $($file.FullName)"
        }
    }
    return $combined
}

if (-not $logfile) {
    Write-Error "No log data retrieved."
    return
}

# 2️⃣ ประมวลผลข้อมูล IN/OUT
$outEntries = @{}
$sessions = @()

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
        $username  = $parts[4]
        $hostName  = $parts[5]
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
            module         = $module
            version        = $version
            host           = $hostName
            username       = $username
            start_datetime = $start_dt
            start_date     = $start_dt.ToString("yyyy-MM-dd")
            start_time     = $start_dt.ToString("HH:mm:ss")
            start_hours    = $start_dt.ToString("HH")
            start_action   = $action
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
                username         = $entry.username
                version          = $entry.version
            }

            $sessions += $session
            $outEntries.Remove($license_id)
        }
    }
}

Write-Host -ForegroundColor Cyan "Total sessions: $($sessions.Count)"
# 3️⃣ ฟังก์ชันแยก Chunk อย่างถูกต้อง
function Split-ToChunks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$InputArray,

        [Parameter(Mandatory = $true)]
        [int]$ChunkSize
    )

    $chunks = New-Object 'System.Collections.Generic.List[Object[]]'
    $totalCount = $InputArray.Count

    for ($i = 0; $i -lt $totalCount; $i += $ChunkSize) {
        $endIndex = [Math]::Min($i + $ChunkSize - 1, $totalCount - 1)
        $chunk = $InputArray[$i..$endIndex]
        $chunks.Add($chunk)
    }

    return $chunks
}

# 4️⃣ ฟังก์ชันส่ง JSON Payload
function Send-JsonPayload {
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [hashtable]$Payload,

        [Parameter(Mandatory)]
        [int]$depth,

        [string]$ContentType = "application/json"
    )

    try {
        $jsonBody = $Payload | ConvertTo-Json -Depth $depth -Compress
        Write-Host "Sending JSON to $Url..."
        Write-Host $jsonBody

        $response = Invoke-WebRequest -Uri $Url -Method Post -Body $jsonBody -ContentType $ContentType -ErrorAction Stop
        return $response.StatusCode
    } catch {
        if ($_.Exception.Response -ne $null) {
            return $_.Exception.Response.StatusCode.Value__
        } else {
            Write-Error "Error sending data: $_"
            return -1
        }
    }
}
function Split-ToChunks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$InputArray,

        [Parameter(Mandatory = $true)]
        [int]$ChunkSize
    )

    $chunks = @()
    for ($i = 0; $i -lt $InputArray.Count; $i += $ChunkSize) {
        $chunk = $InputArray[$i..([Math]::Min($i + $ChunkSize - 1, $InputArray.Count - 1))]
        $chunks += ,$chunk  # comma ทำให้ $chunk เป็น object array
    }

    return ,$chunks  # <== force return เป็น array ของ array
}
# 5️⃣ แบ่งและส่งข้อมูล
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

$function_path = Join-Path -Path $PSScriptRoot -ChildPath 'function.ps1'

if (Test-Path $function_path)
{
    . $function_path  # ✅ dot sourcing (จุด + เว้นวรรค + path)
}
else 
{
    Write-Host "'function.ps1' not found."
    return -1
}

$user = "aapico\itsupport"
$pass = ConvertTo-SecureString "support" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
# ดึง log ไฟล์จาก remote server
$logfile = Invoke-Command -ComputerName 10.10.10.195 -Credential $cred -ScriptBlock {
    $path = Join-Path "C:\ProgramData\Siemens" "License Server\saltd.log"
    $res = Get-Content $path -ErrorAction Stop
    return $res

}

# ตัวแปรเก็บข้อมูล session
$sessions = @()
$outEntries = @{}
$currentDate = $null
$lastDateTime = $null
function Parse-DateFromStartDate {
    param([string]$line)

    if ($line -match '\d{2}:\d{2}:\d{2} \(lmgrd\) \(@lmgrd-SLOG@\) Start-Date: (.+)') {
        $rawDateStr = $matches[1] -replace ' SE Asia.*',''
        return [datetime]::ParseExact($rawDateStr, "ddd MMM dd yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture).Date
    }
    return $null
}

# ใช้ข้อมูลที่ได้จาก remote server โดยตรง
$lines = $logfile

foreach ($line in $lines) {
    $newDate = Parse-DateFromStartDate $line
    if ($newDate) {
        $currentDate = $newDate
        continue
    }

    if ($line -match '^(\d{2}:\d{2}:\d{2}) \(saltd\) (OUT|IN): "([^"]+)" ([^@]+)@(.+)$' -and $currentDate) {
        $timeStr = $matches[1]
        $action = $matches[2]
        $module = $matches[3]
        $user = $matches[4]
        $hostname = $matches[5]

        $timeObj = [datetime]::ParseExact($timeStr, "HH:mm:ss", $null).TimeOfDay

        if ($lastDateTime -and $timeObj -lt $lastDateTime.TimeOfDay) {
            $currentDate = $currentDate.AddDays(1)
        }
        $dt = $currentDate.Add($timeObj)
        $lastDateTime = $dt
        $key = "$user|$hostname|$module"
        #=============================================================================#      
        if ($action -eq "OUT") {
            $outEntries[$key] = @{
                start_datetime = $dt
                start_date = $dt.ToString("yyyy-MM-dd")
                start_time = $dt.ToString("HH:mm:ss")
                user = $user
                hostname = $hostname
                module = $module
            }
        }
        elseif ($action -eq "IN") {
            if ($outEntries.ContainsKey($key)) {
                $start = $outEntries[$key]
                $outEntries.Remove($key)
                $durationMinutes = [math]::Round((($dt - $start.start_datetime).TotalMinutes), 2)

                $sessions += [PSCustomObject]@{
                    start_date = $start.start_date
                    start_time = $start.start_time
                    end_date = $dt.ToString("yyyy-MM-dd")
                    end_time = $dt.ToString("HH:mm:ss")
                    duration_minutes = $durationMinutes
                    hostname = $hostname
                    module = $module
                    username = $user
                }
            }
        }
    }
}
Write-Host -ForegroundColor blue  $sessions.count 

$chunks = Chunked -Iterable $sessions -Size 800 
foreach ($chunk in $chunks) {
    $payload = @{
        ip = 0
        product = "nx"
        data = @($chunk)
    }
    # ระบุ URL API
    $targetUrl = "http://localhost/testing/"
    # เรียก function ส่ง JSON
    $response = Send-JsonPayload -Url $targetUrl -Payload $payload -depth 10
    Write-Host "Response from server: $response"
}
Write-Host "Exported nx to $excelPath"
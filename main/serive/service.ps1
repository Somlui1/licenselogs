Set-Location $PSScriptRoot
. .\function.ps1
. .\hashdb.ps1
#$logfile = "C:\Users\ahroot\Documents\Logfile.rlog"
$logfile = ".\raw.log"
$stateFile = ".\log_state.json"
$global:outputFile = ".\note.rlog"

# stateful delta tracking
# à¹‚à¸«à¸¥à¸” state
# -------------------------------
# 1ï¸âƒ£ Load state from JSON file
# -------------------------------

$state = @{}
if (Test-Path $stateFile) {
    try {
        $stateJson = Get-Content $stateFile -Raw | ConvertFrom-Json
        if ($stateJson) {
            # Convert PSCustomObject â†’ Hashtable
            $stateJson.PSObject.Properties | ForEach-Object { $state[$_.Name] = $_.Value }
        }
    } catch {
        Write-Warning "Failed to read state file. Initializing empty state."
    }
}
# -------------------------------
# 2ï¸âƒ£ Check the last offset for this logfile
# -------------------------------
$lastOffset = 0
if ($state.ContainsKey($logfile)) {
    $lastOffset = $state[$logfile]
}
# -------------------------------
# 3ï¸âƒ£ Check file size
# -------------------------------
$fileSize = (Get-Item $logfile).Length
# If the file is newly created or smaller than the last offset â†’ reset offset
if ($lastOffset -gt $fileSize) { 
    $lastOffset = 0 
}
# -------------------------------
# 4ï¸âƒ£ Read file from Database
$session_logs = Get-SessionLogs
$session_logs_dict = @{}
if( $session_logs.Count -gt 0) 
{ foreach ($row in $session_logs) {$session_logs_dict[$row.keyword] = $row} }
#--------------------------------
$fs = $null
$reader = $null
$outEntries = @{}
$sessions = @{}
$session = $null
$year = get-date -Format "yyyy"
# à¹€à¸›à¸´à¸”à¹„à¸Ÿà¸¥à¹Œà¸­à¹ˆà¸²à¸™à¸ˆà¸²à¸ offset
$lastOffset = 0
try {
    $fs = [System.IO.File]::Open(
        $logfile,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite
    )
    $fs.Seek($lastOffset, 'Begin') | Out-Null
    $reader = New-Object System.IO.StreamReader($fs)
    Add-Content -Value("File has edited at --> " + (Get-Date).ToString() + "`r`n") -Path $outputFile -Encoding UTF8
        while (-not $reader.EndOfStream) 
{
            $line = $reader.ReadLine().TrimEnd()  # à¸¥à¸š newline/space à¸›à¸¥à¸²à¸¢à¸šà¸£à¸£à¸—à¸±à¸”
            Write-Host $line     
            #Insert-LineToFile -Line $line -OutputFile $outputFile
            $line = $line.Trim()
    $parts = $line -split '\s+'
    if ($parts.Count -lt 10) { 
        write-warning "Invalid log line (too few parts): $line"
        continue }
    $action = $parts[0].ToUpper()


 if($action -eq 'INUSE')
    {
        $module = $parts[1]
        $version   = $parts[2]
        $username  = $parts[4]
        $hostName  = $parts[5]
        $hash      = $parts[6]
        $license_id = $parts[10]
        $date = $parts[-2]
        $time = $parts[-1]
        $datetime_str = "$year-$date $time"
        $keyword = "$username|$hostName|$module|$hash|$license_id"
        try {
            $start_dt = [datetime]::ParseExact($datetime_str, "yyyy-MM/dd HH:mm:ss", $null)
        } catch {
            write-warning "Cannot parse date: $datetime_str"
            return
        }

 $session = [PSCustomObject]@{
                start_datetime   = ($start_dt).ToString("yyyy-MM-dd HH:mm")
                start_action     = 'INUSE'
                end_datetime     = ""
                end_action       = ""
                duration_minutes = ""
                host             = $hostName
                module           = $module
                username         = $username
                version          = $version
                keyword          = $keyword
                hash             = $hash
                hash_id          = "$($hash.Trim('"'))-$($license_id)-$(($start_dt).ToString('MMyy'))"
                license_id       = $license_id
            }
            $sessions[$keyword] = $session       
    }


    if($action -eq 'DENY')
    {
        $module = $parts[1]
        $version   = $parts[2]
        $username  = $parts[3]
        $hostName  = $parts[4]
        $hash      = $parts[5]
        $license_id = $parts[9]
        $date = $parts[-2]
        $time = $parts[-1]
        $datetime_str = "$year-$date $time"
        $keyword = "$username|$hostName|$module|$hash|$license_id"
        try {
            $start_dt = [datetime]::ParseExact($datetime_str, "yyyy-MM/dd HH:mm", $null)
        } catch {
            write-warning "Cannot parse date: $datetime_str"
            return
        }

 $session = [PSCustomObject]@{
                start_datetime   = ($start_dt).ToString("yyyy-MM-dd HH:mm")
                start_action     = 'DENY'
                end_datetime     = ""
                end_action       = ""
                duration_minutes = ""
                host             = $hostName
                module           = $module
                username         = $username
                version          = $version
                keyword          = $keyword
                hash             = $hash.Trim('"')
                hash_id          = "$($hash.Trim('"'))-$($license_id)-$(($start_dt).ToString('MMyy'))"
                license_id       = $license_id
            }
            $sessions[$keyword] = $session      
            
    }
    if ($action -eq 'OUT') 
    {
        $module    = $parts[1]
        $version   = $parts[2]
        $username  = $parts[4]
        $hostName  = $parts[5]
        $hash      = $parts[6]
        $license_id = $parts[10]
        $date = $parts[-2]
        $time = $parts[-1]
        $datetime_str = "$year-$date $time"
        $keyword = "$username|$hostName|$module|$hash|$license_id"
        
        #exit -1
        try {
            $start_dt = [datetime]::ParseExact($datetime_str, "yyyy-MM/dd HH:mm:ss", $null)
        } catch {
            write-warning "Cannot parse date: $datetime_str"
            continue
        }
        $outEntries[$keyword] = [PSCustomObject]@{
            module         = $module
            version        = $version
            host           = $hostName
            username       = $username
            start_action   = $action
            start_datetime = $start_dt
            hash             = $hash.Trim('"')
            license_id     = $license_id
            datetime       = $start_dt.ToString("yyyy-MM/dd HH:mm:ss")
            keyword        = $keyword
        }
    }
    elseif ($action -eq 'IN') {
        $hostName = $parts[5]
        $username = $parts[4]
        $module   = $parts[2]  # à¸›à¸£à¸±à¸š index à¹ƒà¸«à¹‰à¸•à¸£à¸‡ module à¸‚à¸­à¸‡ IN
        $hash     = $parts[6]  # à¸›à¸£à¸±à¸š index à¹ƒà¸«à¹‰à¸•à¸£à¸‡ hash à¸‚à¸­à¸‡ IN
        $license_id = $parts[10]
        $keyword = "$username|$hostName|$module|$hash|$license_id"
        $date = $parts[-2]
        $time = $parts[-1]
        $datetime_str = "$year-$date $time"
        try {
            $end_dt = [datetime]::ParseExact($datetime_str, "yyyy-MM/dd HH:mm:ss", $null)
        } catch {
            write-warning "Cannot parse date: $datetime_str"
            continue
        }
        if ($outEntries.ContainsKey($keyword)) {
            $entry = $outEntries[$keyword]
            $duration = ($end_dt - $entry.start_datetime).TotalMinutes
            $session = [PSCustomObject]@{
                start_datetime   = ($entry.start_datetime).ToString("yyyy-MM-dd HH:mm:ss")
                start_action     = $entry.start_action
                end_datetime     = $end_dt.ToString("yyyy-MM-dd HH:mm:ss")
                end_action       = $action
                duration_minutes = [math]::Round($duration, 2)
                host             = $entry.host
                module           = $entry.module
                username         = $entry.username
                version          = $entry.version
                keyword          = $keyword
                hash             = $hash.Trim('"')
                hash_id          = "$($entry.hash.Trim('"'))-$($license_id)-$(($entry.start_datetime).ToString('MMyy'))"
                license_id       = $entry.license_id
            }
            $sessions[$keyword] = $session
            $outEntries.Remove($keyword)
        }
        elseif($session_logs_dict.ContainsKey($keyword))
        {       
            $entry= $session_logs_dict[$keyword]
                $session_start_dt = [datetime]::ParseExact( $entry.datetime, "yyyy-MM/dd HH:mm:ss", $null)
                $duration = ($end_dt - $session_start_dt).TotalMinutes
                $session = [PSCustomObject]@{
                start_datetime   = $entry.datetime
                start_action     = $entry.start_action
                end_datetime     = $end_dt.ToString("yyyy-MM-dd HH:mm:ss")
                end_action       = $action
                duration_minutes = [math]::Round($duration, 2)
                host             = $entry.host
                module           = $entry.module
                username         = $entry.username
                hash             = $hash.Trim('"')
                keyword          = $keyword
                version          = $entry.version
                hash_id          = "$($entry.hash.Trim('"'))-$($license_id)-$(($session_start_dt).ToString('MMyy'))"
                license_id       = $entry.license_id
            }
            $sessions[$keyword] = $session
        }
    }
        }
    #Add-Content -Value("`n") -Path $outputFile -Encoding UTF8
    # à¸­à¸±à¸žà¹€à¸”à¸• offset
    $state[$logfile] = $fs.Position
} finally {
    if ($reader) { $reader.Close() }
    if ($fs) { $fs.Close() }
}
# à¸šà¸±à¸™à¸—à¸¶à¸ state à¸à¸¥à¸±à¸šà¹„à¸Ÿà¸¥à¹Œ JSON
$state | ConvertTo-Json | Set-Content $stateFile
if ($outEntries.Count -gt 0) {
    Upsert-SessionLog -Entries $outEntries.Values
}
if (($sessions.Values.Count -gt 0))
{
    Remove-SessionLogsByKeyword -keyword $sessions.keyword
}


Write-Host "Processed $($sessions.Count) complete sessions."

if($sessions.Values.Count -eq 0)
{
return 
}
exit -1
$payload = $null
$payloadChunks = Split-ToChunks -InputArray $sessions.Values -ChunkSize 1200
foreach ($chunk in $payloadChunks) {
    $payload = @{ 
        ip = 0
        product = "autoform"
        data = @($chunk)
    }
    $targetUrl = "http://10.10.20.177/testing/"
    $response = Send-JsonPayload -Url $targetUrl -Payload $payload -depth 10
    Write-Host "Response from server: $response"

    Start-Sleep -Seconds 2
}


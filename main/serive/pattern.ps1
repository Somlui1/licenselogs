$content = Get-Content -Path "C:\Users\wajeepradit.p\OneDrive - AAPICO Hitech PCL\project\licenselogs\main\serive\raw.log"
$dict = @{}

$content | ForEach-Object {
    $line = $_.Trim()
    $parts = $line -split '\s+'
 $action = $parts[0].ToUpper()
    if ($parts.Count -lt 10) {
        #Write-Host "Skipping short line: $line"
       return  # ข้ามบรรทัดที่มีข้อมูลไม่ครบ
    }
    if ($action -eq 'OUT') {
        $module   = $parts[1]
        $username = $parts[4]
        $hostName = $parts[5]
        $hash     = $parts[6]
        
    }
    elseif ($action -eq 'IN') {
        $module   = $parts[2]
        $username = $parts[4]
        $hostName = $parts[5]
        $hash     = $parts[6]
        exit -1
    }
    else {
        #Write-Warning "Unknown action: $action"
       return  
    }

    $keyword = "$module|$hash|$username|$hostName"

    if (-not $dict.ContainsKey($keyword)) { $dict[$keyword] = @{} }
    if (-not $dict[$keyword].ContainsKey($action)) { $dict[$keyword][$action] = @() }

    $dict[$keyword][$action] += $line
}
$dict.Count  # ตรวจสอบว่ามีค่าแล้ว
$outputFile = ".\log_dict.txt"

# สร้าง content
$content = foreach ($keyword in $dict.Keys) {
    foreach ($action in $dict[$keyword].Keys) {
        foreach ($line in $dict[$keyword][$action]) {
            $line
        }
    }
"
"

}

# เขียนลงไฟล์
$content | Set-Content -Path $outputFile -Encoding UTF8

Write-Host "Export complete: $outputFile"
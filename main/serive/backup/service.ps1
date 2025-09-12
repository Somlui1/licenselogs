.\function.ps1
Set-Location $PSScriptRoot


$logfile = ".\test.rlog"
$stateFile = ".\log_state.json"
$global:outputFile = ".\note.rlog"

Clear-Host
# stateful delta tracking
# โหลด state
if (Test-Path $stateFile) {
    try {
        $stateJson = Get-Content $stateFile -Raw | ConvertFrom-Json
        if ($stateJson) {
            # แปลง PSCustomObject → Hashtable
            $state = @{}
            $stateJson.PSObject.Properties | ForEach-Object { $state[$_.Name] = $_.Value }
        } else {
            $state = @{}
        }
    } catch {
        Write-Warning "Failed to read state file. Initializing empty state."
        $state = @{}
    }
} else {
    $state = @{}
}
# ตรวจสอบ offset ล่าสุด
if ($null -eq $state) { $state = @{} }
$lastOffset = 0
if ($state.ContainsKey($logfile)) {
    $lastOffset = $state[$logfile]
}
# ตรวจสอบขนาดไฟล์ หากไฟล์ถูกสร้างใหม่หรือสั้นกว่า offset
$fileSize = (Get-Item $logfile).Length
if ($lastOffset -gt $fileSize) {
    $lastOffset = 0
}
# เปิดไฟล์อ่านจาก offset
$fs = $null
$reader = $null

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
            $line = $reader.ReadLine().TrimEnd()  # ลบ newline/space ปลายบรรทัด
            Write-Host $line
            Insert-LineToFile -Line $line -OutputFile $outputFile
}
    Add-Content -Value("`n") -Path $outputFile -Encoding UTF8
   
    # อัพเดต offset
    $state[$logfile] = $fs.Position

} finally {
    if ($reader) { $reader.Close() }
    if ($fs) { $fs.Close() }
}
# บันทึก state กลับไฟล์ JSON
$state | ConvertTo-Json | Set-Content $stateFile

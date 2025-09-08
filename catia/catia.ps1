# Requires ImportExcel module: Install-Module ImportExcel
$user = "aapico\itsupport"
$pass = ConvertTo-SecureString "support" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
# 1️⃣ ดึงไฟล์จาก Remote Server
$logfile = Invoke-Command -ComputerName 'ah23itpc0540.aapico.com' -Credential $cred -ScriptBlock {
    $logDir = "C:\ProgramData\DassaultSystemes\LicenseServer\LogFiles"
    $logFiles = Get-ChildItem -Path $logDir -Filter "LicenseServer2025*" -File -Recurse
    $combined = @()

    foreach ($file in $logFiles) {
        try {
            $lines = Get-Content $file.FullName -Encoding UTF8  -ErrorAction Stop
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
#$logFile = "license_denied_log.txt"
$data = @()
# Regex pattern for License Denied lines
$pattern = '(?<datetime>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}:\d{3}) W LICENSESERV (?<feature>\S+) not granted, (?<reason>.*) \( from client (?<client>.*?) \((.*?)\)/.*?\|(?<user>[^|]+)\|(?<user_full>[^|]+)\|(?<license>[^|]+)\|(?<path>.*?) \)'
# Read file line by line
$logfile | ForEach-Object {
    if ($_ -match $pattern) {
        try {
            $dt = [datetime]::ParseExact($matches['datetime'], 'yyyy/MM/dd HH:mm:ss:fff', $null)
        } catch {
            Write-Warning "Invalid datetime format in line: $_"
            return
        }

        $data += [PSCustomObject]@{
            Date    = $dt.Date
            Time    = $dt.ToString("HH:mm:ss.fff")
            Feature = $matches['feature']
            Reason  = $matches['reason']
            User    = $matches['user']
            Client  = $matches['client']
            Path    = $matches['path']
        }
    }
}

# Export to Excel
#$data | Export-Excel -Path "license_denied_report.xlsx" -AutoSize -WorksheetName "DeniedLicenses"

#Write-Output "บันทึกข้อมูลเรียบร้อยใน license_denied_report.xlsx"
# Export to Excel (requires ImportExcel module)
#$data | Export-Excel -Path "license_denied_report.xlsx" -AutoSize -WorksheetName "Report"
#Write-Output "บันทึกข้อมูลเรียบร้อยใน license_denied_report.xlsx"

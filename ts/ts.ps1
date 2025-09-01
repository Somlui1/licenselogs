function Send-JsonPayload {
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [hashtable]$Payload,   # รับเป็น hashtable (object) แล้วจะแปลงเป็น JSON

        [string]$ContentType = "application/json"
    )

    try {
        # แปลง Payload เป็น JSON string
        $jsonBody = $Payload | ConvertTo-Json -Depth 10 -Compress

        Write-Host "Sending JSON to $Url..."
        Write-Host $jsonBody

        # ส่ง POST request
        $response = Invoke-RestMethod -Uri $Url -Method Post -Body $jsonBody -ContentType $ContentType

        return $response
    }
    catch {
        Write-Error "Error sending data: $_"
    }
}

# เตรียม payload
#$payload = @{
#    ip = 0
#    product = "nx"
#    parsed_data = @(
#        @{
#            start_date       = "2025-08-29"
#            start_time       = "08:30:00"
#            end_date         = "2025-08-29"
#            end_time         = "10:15:00"
#            duration_minutes = "105.5"
#            hostname         = "server01.example.com"
#            module           = "auth_module"
#            username         = $null
#        },
#        @{
#            start_date       = "2025-08-29"
#            start_time       = "08:30:00"
#            end_date         = "2025-08-29"
#            end_time         = "10:15:00"
#            duration_minutes = "105.5"
#            hostname         = "server01.example.com"
#            module           = "auth_module"
#            username         = $null
#        }
#    )
#}
#
## ระบุ URL API
#$targetUrl = "http://your-api-server/endpoint"
#
## เรียก function ส่ง JSON
#$response = Send-JsonPayload -Url $targetUrl -Payload $payload
#
## แสดง response จาก server
#$response
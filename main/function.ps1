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
        # แปลง Payload เป็น JSON string
        $jsonBody = $Payload | ConvertTo-Json -Depth $depth -Compress

        Write-Host "Sending JSON to $Url..."
        Write-Host $jsonBody

        # ใช้ Invoke-WebRequest เพื่อให้ได้ Response object ที่มี StatusCode
        $response = Invoke-WebRequest -Uri $Url -Method Post -Body $jsonBody -ContentType $ContentType -ErrorAction Stop

        # คืนค่า StatusCode (ตัวเลข เช่น 200)
        return $response.StatusCode
    }
    catch {
        if ($_.Exception.Response -ne $null) {
            return $_.Exception.Response.StatusCode.Value__
        } else {
            Write-Error "Error sending data: $_"
            return -1  # ใช้ -1 เป็นตัวบ่งชี้ว่าไม่มี response code (เช่น network error)
        }
    }
} 
function Chunked {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Iterable,

        [Parameter(Mandatory=$true)]
        [int]$Size
    )

    for ($i = 0; $i -lt $Iterable.Count; $i += $Size) {
        $chunk = $Iterable[$i..([Math]::Min($i + $Size - 1, $Iterable.Count - 1))]
        ,$chunk   # comma operator ทำให้ return เป็น array เดียว ไม่ flatten
    }
}


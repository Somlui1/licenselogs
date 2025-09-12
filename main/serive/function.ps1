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

function Insert-LineToFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Line,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile = ".\note.rlog"
    )
    $Line = $Line.TrimEnd()  # ลบ space / newline ปลายบรรทัด
    $success = $false
    $retry = 0
    while (-not $success -and $retry -lt 3) {
        try {
            Add-Content -Path $OutputFile -Value ($Line) -Encoding UTF8
            $success = $true
        } catch {
            Write-Warning "Failed to write to file. Retry $($retry + 1): $_"
            Start-Sleep -Milliseconds 100
            $retry++
        }
    }

    if (-not $success) {
        Write-Warning "Cannot write line even after retries: $Line"
    }
}
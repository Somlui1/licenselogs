function Split-ToChunks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$InputArray,

        [Parameter(Mandatory = $true)]
        [int]$ChunkSize
    )

    for ($i = 0; $i -lt $InputArray.Count; $i += $ChunkSize) {
        $chunk = $InputArray[$i..([Math]::Min($i + $ChunkSize - 1, $InputArray.Count - 1))]
        ,$chunk  # ทำให้ return เป็น array of arrays
    }
}
$data = 1..10
$chunks = Split-ToChunks -InputArray $data -ChunkSize 3

foreach ($chunk in $chunks) {
    Write-Output "Chunk: $($chunk -join ', ')"
}
function Get-MongoDataByObjectId {
    param (
        [string]$MongoShellPath = "C:\Users\wajeepradit.p\AppData\Local\Programs\mongosh\mongosh.exe",
        [string]$MongoUri = "mongodb://admin:it%40apico4U@10.10.10.181:27017/?authSource=admin",
        [string]$DatabaseName = "logs",
        [string]$CollectionName = "AHA",
        [string]$ObjectIdString,
        [switch]$VerboseOutput
    )
    if (-not $ObjectIdString) {
        throw "กรุณาระบุ ObjectIdString เช่น '6881f9316936defec5abb109'"
    }
    $jsQuery = @"
db.getSiblingDB('$DatabaseName').$CollectionName.find({ _id: ObjectId('$ObjectIdString') }).map(doc => {
  doc._id = doc._id.toString();
  return doc;
})
"@
    if ($VerboseOutput) {
        Write-Host "Running mongosh with query:"
        Write-Host $jsQuery
    }
    try {
        $jsonResult = & "$MongoShellPath" $MongoUri --quiet --eval $jsQuery 2>&1
        if (-not $jsonResult -or $jsonResult.Trim() -eq "") {
            Write-Warning "ไม่พบข้อมูลหรือไม่สามารถเชื่อมต่อ MongoDB ได้"
            return $null
        }
        $data = $jsonResult | Out-String | ConvertFrom-Json
        return $data
    }
    catch {
        Write-Error "เกิดข้อผิดพลาด: $_"
    }
}
$result = Get-MongoDataByObjectId `
    -MongoShellPath "C:\Users\wajeepradit.p\AppData\Local\Programs\mongosh\mongosh.exe" `
    -MongoUri "mongodb://admin:it%40apico4U@10.10.10.181:27017/?authSource=admin" `
    -DatabaseName "logs" `
    -CollectionName "AHA" `
    -ObjectIdString "6881f9316936defec5abb109" `
    -VerboseOutput
# แสดงผลลัพธ์

if ($result -and $result.result -and $result.result.rows) {
    $result.result.rows | Out-File -FilePath "C:\Users\wajeepradit.p\licenselogs.txt" -Encoding UTF8
    Write-Host "Exported logs to C:\Users\wajeepradit.p\licenselogs.txt"
} else {
    Write-Warning "ไม่พบข้อมูล rows ในผลลัพธ์"
}
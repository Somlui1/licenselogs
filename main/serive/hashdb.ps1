if (-not (Get-Module -ListAvailable -Name SQLite)) {
    try {
        $moduleName = "SQLite"
        Install-Module -Name $moduleName -Scope CurrentUser -Force
    } catch {
        Write-Error "Failed to install module '$moduleName'. Please install it manually."
        return
    }
}

$Global:dbPath = Join-Path $PSScriptRoot 'hash\hash.db'

# สร้างตาราง
Invoke-SqliteQuery -DataSource $dbPath -Query @"
CREATE TABLE IF NOT EXISTS session_logs (
    module TEXT,
    version TEXT,
    username TEXT,
    host TEXT,
    hash TEXT,
    license_id TEXT,
    datetime TEXT,
    keyword TEXT UNIQUE
);
"@

function Upsert-SessionLog {
    param(
        [string]$DBPath = $Global:dbPath,
        [PSObject[]]$Entries
    )

    foreach ($Entry in $Entries) {
        $sql = @"
INSERT OR REPLACE INTO session_logs (module, version, username, host, hash, license_id, datetime, keyword)
VALUES (@module, @version, @username, @host, @hash, @license_id, @datetime, @keyword);

"@
        Invoke-SqliteQuery -DataSource $DBPath -Query $sql -SqlParameters @{
            module     = $Entry.module
            version    = $Entry.version
            username   = $Entry.username
            host       = $Entry.host
            hash       = $Entry.hash
            license_id = $Entry.license_id
            datetime   = $Entry.datetime
            keyword    = $Entry.keyword
        }
    }
}

function Get-SessionLogs {
    param(
        [string]$DBPath =$Global:dbPath,
        [string]$Module,
        [string]$Username,
        [datetime]$StartDate,
        [datetime]$EndDate
    )

    $sql = "SELECT * FROM session_logs WHERE 1=1"
    $params = @{}

    if ($Module)   { $sql += " AND module = @module";       $params["module"]    = $Module }
    if ($Username) { $sql += " AND username = @username";   $params["username"]  = $Username }
    if ($StartDate){ $sql += " AND datetime >= @startdate"; $params["startdate"] = $StartDate.ToString("yyyy-MM-dd HH:mm:ss") }
    if ($EndDate)  { $sql += " AND datetime <= @enddate";   $params["enddate"]   = $EndDate.ToString("yyyy-MM-dd HH:mm:ss") }

    return Invoke-SqliteQuery -DataSource $DBPath -Query $sql -SqlParameters $params
}

function Remove-SessionLogsByKeyword {
    param(
        [string]$DBPath =$Global:dbPath,
        [array]$Keywords
    )

    if (-not $Keywords -or $Keywords.Count -eq 0) {
        Write-Warning "No keywords provided. Exiting."
        return
    }

    foreach ($kw in $Keywords) {
        Invoke-SqliteQuery -DataSource $DBPath -Query "DELETE FROM session_logs WHERE keyword = @keyword" -SqlParameters @{
            keyword = $kw
        }
    }

    Write-Host "Deleted $($Keywords.Count) row(s) from session_logs."
}


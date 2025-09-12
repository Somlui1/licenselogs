. .\hashdb.ps1
#$dbPath = ".\test.db"
#
## สร้างตาราง (ครั้งแรก)
#Invoke-SqliteQuery -DataSource $dbPath -Query @"
#CREATE TABLE IF NOT EXISTS users (
#    id INTEGER PRIMARY KEY AUTOINCREMENT,
#    name TEXT NOT NULL,
#    age INT NOT NULL
#);
#"@
#
## Insert ข้อมูล
#Invoke-SqliteQuery -DataSource $dbPath -Query "INSERT INTO users (name, age) VALUES ('Alice', 25);"
#Invoke-SqliteQuery -DataSource $dbPath -Query "INSERT INTO users (name, age) VALUES ('Bob', 30);"
#
## อ่านข้อมูลกลับมา
#Invoke-SqliteQuery -DataSource $dbPath -Query "SELECT * FROM users;"

Get-SessionLogs


#IN 1 af_company_string 5.0 apichart.c aits25a1nb0300 "sVNk5TR9H9Vv2t-QBBl7CXejzuVREbUb" 1 1 0 e9 09/04 19:49:43
#IN 1 af_autoform_seat_nu 5.0 apichart.c aits25a1nb0300 "sVNk5TR9H9Vv2t-QBBl7CXejzuVREbUb" 1 1 0 4f3 09/04 19:49:43
#IN 1 af_explorer_addon_nu 5.0 apichart.c aits25a1nb0300 "sVNk5TR9H9Vv2t-QBBl7CXejzuVREbUb" 1 0 0 6e 09/04 19:49:43
#IN 1 af_stampingadviser_addon_nu 5.0 apichart.c aits25a1nb0300 "sVNk5TR9H9Vv2t-QBBl7CXejzuVREbUb" 1 0 0 5bc 09/04 19:49:43
#IN 1 af_diedesigner_addon_nu 5.0 apichart.c aits25a1nb0300 "sVNk5TR9H9Vv2t-QBBl7CXejzuVREbUb" 1 1 0 475 09/04 19:49:43
#IN 1 af_compensator_addon_nu 5.0 apichart.c aits25a1nb0300 "sVNk5TR9H9Vv2t-QBBl7CXejzuVREbUb" 1 0 0 386 09/04 19:49:43

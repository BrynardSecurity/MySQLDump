<# Head #>

<# Variables #>
$mysql_server = "localhost"
$mysql_defaults = $env:ProgramData+"MySQL\MySQL Server 8.0\my.ini"
$dbName = "enterpriseinspectordb"
$mysqlDLL=${env:ProgramFiles(x86)}+"\MySQL\MySQL Installer for Windows\MySql.Data.dll"
$mysql_user=backup
$mysql_password=cqvqjY6HxVs3Cvtt7AHqjyJe3kfbp83Wek4
$timestamp=Get-Date yyyyMMddHHmmss
Write-Host -ForegroundColor Magenta $timestamp

$rootdir = "Y:"
$year=Get-Date -Format yyyy
$month=Get-Date -UFormat %b
$currentbackup_dir = $rootdir+"\"+$year+"\"+$month

<# Functions #>

<# Script #>
#Check to see if folders exist
if ((Test-Path -Path $currentbackup_dir) -eq $False) {
    Write-Host -ForegroundColor Red "Directory doesn't exist!"
    Write-Host -ForegroundColor Magenta "Creating directory..."
    mkdir $rootdir$yearVar\$monthVar
    if ((Test-Path -Path $currentbackup_dir) -eq $True) {
        Write-Host -ForegroundColor Green "Directory exists, moving to database backup...."
    } 
} ElseIf ((Test-Path -Path $currentbackup_dir) -eq $True) {
    Write-Host -ForegroundColor Green "Directory exists, moving to database backup...."
}

#Connect to MySQL
[void].[System.Reflectio.Assembly]::LoadFrom($mysqlDLL)
[System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")

$cn = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
$cn.ConnectionString = "SERVER=$mysql_server;DATABASE=information_schema;UID=$mysql_user;PWD=$mysql_password"
$cn.Open()

$cm = New-Object -TypeName MySql.Data.MySqlClient.MySqlCommand
$sql = "SELECT DISTINCT CONVERT(SCHEMA_NAME USING UTF8) AS dbName, CONVERT(NOW() USING UTF8) AS dtStamp FROM SCHEMATA ORDER BY dbName ASC"
$cm.Connection=$cn
$cm.CommandText=$sql
$dr = $cm.ExecuteReader()

while ($dr.Read()) {
    $dbname = [string]$dr.GetString(0)
    if ($dbname -match $dbName) {
        Write-Host -ForegroundColor Magenta "Backing up database: " $dr.GetString(0)

        $backupfilename = $timestamp + "_" + $dr.GetString(0) + ".sql"
        $backuppathandfile = $currentbackup_dir + "" + $backupfilename
        if (Test-Path($backuppathandfile)) {
            Write-Host -ForegroundColor Red "Backup file '" $backuppathandfile "' already exists. Existing file will be deleted."
            Remove-item $backuppathandfile
        }
        cmd /c " `"$pathtomysqldump`" -h $mysql_server -u $mysql_user -p$mysql_password $dbname > $backuppathandfile "
        if (test-path($backuppathandfile)) {
            Write-Host "backup created. Presence of file verified"
        }
    }
    Write-Host " "
}

$cn.Close()

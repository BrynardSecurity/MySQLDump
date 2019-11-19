<# Head #>

<# Variables #>
# Core settings - you will need to set these 
$root="\\pdc01-hq.joe-burg.com\SQL-Backups\EEI"
$mysql_server = "localhost"
$year=Get-Date -Format yyyy
$month=Get-Date -UFormat %b
$mysql_defaults=${env:ProgramData}+"\MySQL\MySQL Server 8.0\my.ini"
$mysql_bin=${env:ProgramFiles}+"\MySQL\MySQL Server 8.0\bin\"
$mysql_dump=".\mysqldump.exe"
$backupstorefolder= "$root"+"\"+$year+"\"+$month+"\"
$dbName = "enterpriseinspectordb"
$results_file = "eeidb."+$timestamp+".sql"
$timestamp=Get-Date -Format yyyyMMddHHmmss
$log_file="eei-dump-log."+$timestamp+".log"
$start_time = Get-Date
$current_backup = $backupstorefolder+"\"+$results_file+"\"+$log_file

<# Functions #>

function BackupDir {
   Write-Host -ForegroundColor Cyan "Verifying file system path for backup root directory..."
   if ((Resolve-Path $root) -ne $False) {
        Write-Host -ForegroundColor Red "File system path does not exist! Adding PSDrive..."
        New-PSDrive -Name Y -PSProvider FileSystem -Root \\pdc01-hq.joe-burg.com\SQL-Backups\EEI
   } ElseIf ((Resolve-Path $root) -ne $False) {
        Write-Host -ForegroundColor Green "File system path for backup root directory exists, proceeding with backup directory creation..."
   }
    Write-Host -ForegroundColor Green "Preparing output folder for $($dnBame) backup..."
    if ((Test-Path -Path $backupstorefolder) -eq $False) {
        Write-Host -ForegroundColor Red "Directory doesn't exist!"
        Write-Host -ForegroundColor Magenta "Creating directory..."
        mkdir $backupstorefolder
        if ((Test-Path -Path $backupstorefolder) -eq $True) {
            Write-Host -ForegroundColor Green "Directory exists, moving to database backup...."
        } 
    } ElseIf ((Test-Path -Path $backupstorefolder) -eq $True) {
        Write-Host -ForegroundColor Green "Directory exists, moving to database backup...."
    }
}


function MySQLDump {

    $file=$backupstorefolder+$results_file

    pushd $mysql_bin
    $cmd='.\mysqldump.exe --defaults-file=$mysql_defaults --verbose --databases $dbName --extended-insert --routines --disable-keys --result-file $backupstorefolder$results_file 2> $backupstorefolder"\"$log_file'
    
    Write-Host -Foregroundcolor Yellow "Please wait... Dumping to $($log_file)"

   
    Invoke-Expression $cmd

    Write-Host -ForegroundColor Green "MySQL Dump complete! Mysql dump file size: "
    Write-Host -Foregroundcolor Magenta "Database dump size for $($results_file) in KB: "((Get-Item $file).length/1KB)"KB"
    Write-Host -Foregroundcolor Cyan "Database dump size for $($results_file) in MB: "((Get-Item $file).length/1MB)"MB"
    Write-Host -Foregroundcolor Green "Database dump size for $($results_file) in GB: "((Get-Item $file).length/1GB)"GB"
    popd
}

function CompressBackUp {
    $output = $backupstorefolder+"eeidb."+$timestamp+".zip"

    Write-Host -ForegroundColor Green "Compressing backup..."
    Compress-Archive -Path $backupstorefolder -DestinationPath $output
    
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

function CleanUp {
    $files=Get-ChildItem -Path $backupstorefolder -Exclude *.zip

    if ((Test-Path -Path $backupstorefolder) -eq $True) {
        Write-Host -ForegroundColor Red "Files exist! Cleaning up!"

    foreach ($i in $files) {
        Remove-Item  -Path $i -Exclude *.zip -Force

        Write-Host -ForegroundColor Yellow "Cleaning up $i"
        Write-Host -ForegroundColor Magenta "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
        }
       }ElseIf ((Test-Path -Path $current_backup) -eq $False) {
            Write-Output -ForegroundColor Green "No files to cleanup! Exiting..."

            Exit
     }
 }

<# Script #>
#Check to see if folders exist
#Set-ExecutionPolicy -ExecutionPolicy ByPass
BackupDir;
MySQLDump;
CompressBackUp;
CleanUp;


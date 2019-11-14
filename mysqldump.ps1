function ZipAndDeleteFile([string] $file, [string] $saveLocation)
{
    $command = [string]::Format("`"{0}`" a -ep -df `"$saveLocation`" `"$file`"", $winrarPath);
    iex "& $command";
}
 
function GetCurrentDateTime
{
    return Get-Date -Format yyyyMMdd_HHmmss;
}
 
Class DatabaseEntry {
    [string] $DatabaseName;
    [string] $DatabaseBackupPath;
    [string] $DatabaseFilename;
 
    DatabaseEntry([string] $databaseName, $databaseBackupPath, $databaseFilename)
    {
        $this.DatabaseName = $databaseName;
        $this.DatabaseBackupPath = $databaseBackupPath;
        $this.DatabaseFilename = $databaseFilename;
    }
}
 
 
$debugMode = $false;  # Show errors from mysqldump
$winrarPath = "C:\Program Files\WinRAR\WinRAR.exe";  # Path to WinRAR
 
$logFilePath = "C:\Database Backups\";  # Folder where the log file will be created in
$logFileName = "backup_log.log";  # Filename of the log file
$logFileFullPath = [io.path]::combine($logFilePath, $logFileName);  # The full path of the log file (ignore this, it will get populated from the 2 variables above)
 
$mysqlDumpLocation = "C:\MySQL\mysqldump.exe";  # Path to the mysqldump executable. This is required in order to be able to dump the databases.
 
<# The path where the database files will be stored. 
   This is simply here to speed up the assigning of paths for the DatabaseEntry objects. You can set an entirely different path for each database. #>
$databaseBackupLocation = "C:\Database Backups\MySQL";  
 
 
$databaseIp = "<Your MySQL server IP>";  # Database IP or Hostname
$databaseUsername = "<MySQL User>";  # Database username (it should have access to all the databases you need to backup)
$databasePassword = "<MySQL password for user>";  # The password of the user
 
<# Here is where you specify which databases you want to backup.
   The DatabaseEntry object takes three arguments: 
   1) The database name, this should match the name of the database you have in your MySQL server
   2) The path where you want the database to be stored (without the filename)
   3) The filename of backup file without the extension (a timestamp will be added automatically so you do need to worry about it) 
#>
$databases = New-Object System.Collections.ArrayList;
[void]$databases.Add([DatabaseEntry]::New("database1", [io.path]::combine($databaseBackupLocation, "database1_foldername"), "database1"));
[void]$databases.Add([DatabaseEntry]::New("database2", [io.path]::combine($databaseBackupLocation, "database2_foldername"), "database2"));
[void]$databases.Add([DatabaseEntry]::New("database3", [io.path]::combine($databaseBackupLocation, "database3_foldername"), "database3"));
 
md -Force $logFilePath | Out-Null  # Create the path for the log file
 
Out-File $logFileFullPath -InputObject "Starting backup operation" -Append;
 
# Iterate and process all the database entries
foreach ($database in $databases.GetEnumerator())
{
    try
    {
        Out-File $logFileFullPath -InputObject ([string]::Format("Backing up {0}...",$database.DatabaseFilename)) -Append;
        $date = GetCurrentDateTime;
        md -Force $database.DatabaseBackupPath | Out-Null
        $saveFilePath = [string]::format("{0}\{1}_{2}.sql", $database.DatabaseBackupPath, $database.DatabaseFilename, $date);
        
        $command = [string]::format("`"{0}`" -u {1} -p{2} -h {3} --quick --default-character-set=utf8 --routines --events `"{4}`" > `"{5}`"",
            $mysqlDumpLocation,
            $databaseUsername,
            $databasePassword,
            $databaseIp,
            $database.DatabaseName,
            $saveFilePath);
 
        $mysqlDumpError;
        Invoke-Expression "& $command" -ErrorVariable mysqlDumpError;  # Execute mysqldump with the required parameters for each database
 
        # If debug mode is on then you will see the errors mysqldump generates in the log file.
        if ($debugMode -eq $true)
        {
            Out-File $logFileFullPath -InputObject $mysqlDumpError -Append;            
        }
        
        $zipFileLocation = [string]::format("{0}\{1}_{2}.zip", $database.DatabaseBackupPath, $database.DatabaseFilename, $date);
        ZipAndDeleteFile $saveFilePath $zipFileLocation;  # Zip the file and delete the file that was zipped.
        $logEntry = [string]::Format("[{0}] Successfully backed up {1}", $date, $database.DatabaseName);
        Out-File $logFileFullPath -InputObject $logEntry -Append;
    }
    catch [Exception]
    {        
        $exceptionMessage = $_.Exception.Message;
        $logEntry = [string]::Format("[{0}] Failed to backup up {1}. Reason: {2}", $date, $database.DatabaseName, $exceptionMessage);
        Out-File $logFileFullPath -InputObject $logEntry -Append;
    }
}
 
Out-File $logFileFullPath -InputObject "Backup operation completed" -Append;
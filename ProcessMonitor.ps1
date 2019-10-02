Clear-Host

$hostname = hostname
#TO Upper 
$hostname = $hostname.ToUpper()

$success = "value=1"
$failed = "value=0"

$sleep_duration = 0 

$processFile = ".\process.list"
$confFile = ".\config.json"

#Logging initializations: change as you deem fit
$LogDir = "C:\AppDynamics\ProcessMonitor"
$ilogFile = "ProcessMonitor.log"

$LogPath = $LogDir + '\' + $iLogFile

# Function to Write into Log file
Function Write-Log {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG")]
        [String]
        $Level = "INFO",

        [Parameter(Mandatory = $True)]
        [string]
        $Message,

        [Parameter(Mandatory = $False)]
        [string]
        $logfile
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Level $Message"
    if ($logfile) {
        Add-Content $logfile -Value $Line
    }
    else {
        Write-Output $Line
    }
}
#Checking for existence of logfolders and files if not create them.
if (!(test-path $LogDir)) {
    New-Item -Path $LogDir -ItemType directory
    New-Item -path $LogDir -name $iLogFile -Itemtype File
}
else {
    Write-Log INFO "$LogDir exists" $LogPath
        
}

if (!(test-path $processFile)) {
    Write-Log ERROR "The $processFile file must exist in the script's path. Quitting " $LogPath
    Write-Host "missing $processFile"
    exist 
} 

if(!(test-path $confFile)) {
   Write-Log ERROR "The $confFile file must exist in the script's path. Quitting " $LogPath
   Write-Host "missing $confFile"
    exist 
}

$confFileContent = (Get-Content $confFile -Raw) | ConvertFrom-Json

$tier_id = $confFileContent.ConfigItems | where { $_.Name -eq "tierID" } | Select -ExpandProperty Value
$businessApplicationName = $confFileContent.ConfigItems | where { $_.Name -eq "AppName" } | Select -ExpandProperty Value

Write-Host "Value from JSON  are teirID:  $tier_id AppName: $businessApplicationName"

$metric_prefix = "name=Server|Component:$tier_id|Custom Metrics|$hostname|Process Monitor|"

$processFileContent = Get-Content($processFile)

ForEach($Name in $processFileContent) {
    
    #$ErrorActionPreference='stop'
    #$serviceName = Get-Service -DisplayName $Value 
    try { 
        $serviceName = Get-Service -Name $Name

        sleep $sleep_duration

        if ($serviceName -match $Name) {
            #set service_name in metric prefix
        
            Write-Log INFO "Service Name: See next line " $LogPath  
            Write-Log INFO $serviceName.DisplayName $LogPath
            Write-Log INFO "Service Status: See next line" $LogPath
            Write-Log INFO $serviceName.Status $LogPath
           # Write-Host  "Found " $serviceName.DisplayName "and status is" $serviceName.Status 
        
            #$service_name|$metric_name,
            $metric_prefix_new = "$metric_prefix" + "$Name" + "|Satus, "
       
            Write-Log INFO "New Metric prefix = $metric_prefix_new" $LogPath
        
            if ($serviceName.Status -eq "Running") {
                Write-Log INFO "Sending 1 to AppD for $Name" $LogPath
                Write-Host $metric_prefix_new$success
            }
            else {
            
                Write-Log ERROR "Service failed to respond. Sending zero to AppDynamics" $LogPath
                Write-Host $metric_prefix_new$failed

                #Push an event 
                & "$PSScriptRoot\push_events.ps1" -ServiceName $Name -ServerName $hostname -businessApplicationName $businessApplicationName 
            }

        }
        else {
            $msg = "$Name :$Value is not found - check to make sure it is installed on this server $hostname"
            Write-Log ERROR $msg $LogPath
            Write-Host $msg
        }

    }
    catch {
        $msg = "An error occured in the catch block, it's most likely that the $Name service doesn't exist or your controller creds are not correct"
        Write-Log ERROR $msg $LogPath
        Write-Host $msg

    }
}


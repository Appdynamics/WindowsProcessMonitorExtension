Clear-Host

$tier_id = "CHANGE_ME"
$hostname = hostname
#TO Upper 
$hostname = $hostname.ToUpper()
$metric_prefix = "name=Server|Component:$tier_id|Custom Metrics|$hostname|Skype Process Monitor|"

$success = "value=1"
$failed = "value=0"

$sleep_duration = 5 

$hashtable = @{
    #ServiceName="ServiceDisplayName"
    "AppDyanmics DB Agent" = "AppDyanmics DB Agent"
    "App D DB Agent" = "App D DB Agent"
    # uncomment these lines for TPICAP 
    #FTA        = "Skype for Business Server File Transfer Agent"
    #LYNCBACKUP = "Skype for Business Server Backup Service"
    #MASTER     = "Skype for Business Server Master Replicator Agent"
    #REPLICA    = "Skype for Business Server Replica Replicator Agent"
    #RTCASMCU   = "Skype for Business Server Application Sharing"
    #RTCATS     = "Skype for Business Server Audio Test Service"
    #RTCAVMCU   = "Skype for Business Server Audio/Video Conferencing"
    #RTCCAA     = "Skype for Business Server Conferencing Attendant"
    #RTCCAS     = "Skype for Business Server Conferencing Announcement"
    #RTCCLSAGT  = "Skype for Business Server Centralized Logging Service Agent"
    #RTCCPS     = "Skype for Business Server Call Park"
    #RTCDATAMCU = "Skype for Business Server Web Conferencing"
    #RTCHA      = "Skype for Business Server Health Agent"
    #RTCIMMCU   = "Skype for Business Server IM Conferencing"
    #RTCMEDSRV  = "Skype for Business Server Mediation"
    #RTCRGS     = "Skype for Business Server Response Group"
    #RtcSrv     = "Skype for Business Server Front-End"
    #RTCXMPPTGW = "Skype for Business Server XMPP Translating Gateway"
}

#Logging initializations: change as you deem fit
$LogDir = "C:\AppDynamics\SkypeProcessMonitorLogs"
$ilogFile = "SkypeProcessMonitor.log"

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

#Start iteration through hash table 

$hashtable.Keys | ForEach-Object {
    $Name = $_
    $Value = $hashtable.$Name
    
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
                & "$PSScriptRoot\push_events.ps1" -ServiceName $Name -ServerName $hostname
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


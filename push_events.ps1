param([string]$ServiceName, [string]$ServerName, [string]$businessApplicationName, [string]$controllerHostName, [string]$OAuthToken)

Write-Host "ServiceName is $ServiceName and ServerName is : $serverName "
Write-Host " appName: $businessApplicationName "
Write-Host "controller : $controllerHostName and token: SCRAMBLED"

# -ServiceName "ServiceName"

# Ref: https://docs.appdynamics.com/display/PRO45/Alert+and+Respond+API 
# Look up the application id

# Create the event based on the application id

#Controller hostname
$hostname = $controllerHostName

$endpoint_create_event = "/controller/rest/applications/<application_id>/events?"

#Filter on applications that existed in the last week, return in json format
$endpoint_get_applications = "/controller/rest/applications?output=json"
#&time-range-type=BEFORE_NOW&duration-in-mins=10080"

$url = $hostname + $endpoint_get_applications

#Write-Host "Connecting to URL: $url"

#$token = "ASecretToken" #not using this now 

#$user = "iogbole@customer1"
#$pass = "CHANGE_ME"
#$pair = "${user}:${pass}"
#$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
#$base64 = [System.Convert]::ToBase64String($bytes)
#$basicAuthValue = "Basic $base64"

$JWTToken = "Bearer $OAuthToken"

$header = @{
    Accept        = 'application/json'
    Authorization =  $JWTToken
    ContentType   = 'application/json'
}

$params = @{
    Uri     = $url
    Headers = $header
    Method  = 'GET'
    #	Body = $body
    #	ContentType = 'application/json'
    #	Accept = 'application/json'
}

#Write-host "Make the call"
$applicationObjects = Invoke-RestMethod @params #  -OutFile response1.txt

$targetApplication = $applicationObjects | where { $_.Name -eq $businessApplicationName }
$targetApplicationID = $targetApplication.id

# Update the URL to reference the correct application
$endpoint_create_event = $endpoint_create_event -replace "<application_id>", "${targetApplicationID}"
$endpoint_create_event | Out-Host

#$body = @{
#	$summary = "<ENVIRONMENT>-<Build Number>-<Deployment Number>"
#    summary         = "Event Details"
#    severity        = 'INFO'
#    eventType       = "CUSTOM"
#    customeventtype = "APPLICATION_DEPLOYMENT"
#}

$summary = "$ServiceName Service is Down on $ServerName server"
$severity = "ERROR" #this becomes CRITICAL in the controller UI 
$eventType = "CUSTOM" #CUSTOM
$customeventtype = $businessApplicationName 

$endpoint_create_event = "${endpoint_create_event}summary=${summary}"
$endpoint_create_event = "${endpoint_create_event}&severity=${severity}"
$endpoint_create_event = "${endpoint_create_event}&eventtype=${eventType}"
$endpoint_create_event = "${endpoint_create_event}&customeventtype=${customeventtype}"

$endpoint_create_event | Out-Host

$url = $hostname + $endpoint_create_event

#Write-Host $url 

$params = @{
    Uri     = $url
    Headers = $header
    Method  = 'POST'
    #	Body = $body
    #	ContentType = 'application/json'
    #	Accept = 'application/json'
}

try {

    Write-Host  @params

    $applicationObjects = Invoke-RestMethod @params
}
catch {
    # Dig into the exception to get the Response details.
    # Note that value__ is not a typo.
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
}

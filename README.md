# AppDynamicsWindowsProcessMonitor

Instructions

1. Right click on the downloaded zip and unblock it before you unzip

2. List the Services you want to monitor in the proces.list file.

3. Modify the Config.JSON file. Change only the Value parameters, not the names.

       * tierID - Follow the instructions in this doc to get a component ID -           

https://community.appdynamics.com/t5/Knowledge-Base/How-do-I-troubleshoot-missing-custom-metrics-or-extensions/ta-p/28695#Configuring%20an%20Extension

      * AppName: The Application name in AppDynamics  Controller. All events will be sent to this application

      *  OAuthToken : Ask an AppDynamics Admin to generate an API client Token.  https://docs.appdynamics.com/display/PRO45/API+Clients

4. Copy the entire folder into the monitors folder in a Machine Agent

5. Restart the Machine Agent Service

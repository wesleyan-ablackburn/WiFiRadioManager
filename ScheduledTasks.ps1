If (Test-Path -Path "C:\ProgramData\WiFiRadioState") {
} else {
  New-Item -ItemType directory -Path "C:\ProgramData\WiFiRadioState\" > $null
}

Copy-Item -Path "$dirFiles\Set-WiFiRadioState.ps1" -Destination "C:\ProgramData\WiFiRadioState\" -Force

$Triggers = @()
$TaskName = "WiFi Radio State Correction"
$TaskDescription = "This task ensures the WiFi radio is on at all times."
$Arguments = "-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File ""C:\ProgramData\WiFiRadioState\Set-WiFiRadioState.ps1"" -RadioStatus ""On"""
$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $Arguments
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$EventTriggerClass = Get-CimClass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$EventTrigger = $EventTriggerClass | New-CimInstance -ClientOnly
$EventTrigger.Enabled = $true
$EventTrigger.Subscription = "<QueryList><Query Id=""0"" Path=""System""><Select Path=""System"">*[System[Provider[@Name='Netwtw10'] and EventID=7012]]</Select></Query></QueryList>"
$Triggers +=  New-ScheduledTaskTrigger -AtStartup
$Triggers += $EventTrigger
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -StartWhenAvailable
Register-ScheduledTask -Action $Action -Principal $Principal -Trigger $Triggers -Settings $Settings -TaskName $TaskName -Description $TaskDescription -Force

Write-Log -Message "Creating scheduled task 2/2..." -LogType CMTrace
$Triggers = @()
$TaskName = "WiFi Reconnection"
$TaskDescription = "This task will power cycle the WiFi radio in the event a user intentionally disconnects from specified SSID. In turn, the client will reconnect to preferred network (per auto-connect in the WiFi profile)."
$Arguments = "-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File ""C:\ProgramData\WiFiRadioState\Set-WiFiRadioState.ps1"" -Bounce"
$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $Arguments
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$EventTriggerClass = Get-CimClass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$EventTrigger = $EventTriggerClass | New-CimInstance -ClientOnly
$EventTrigger.Enabled = $true
$EventTrigger.Subscription = "<QueryList><Query Id=""0"" Path=""Microsoft-Windows-WLAN-AutoConfig/Operational""><Select Path=""Microsoft-Windows-WLAN-AutoConfig/Operational"">*[EventData[Data[@Name='ReasonCode']='2'] and EventData[Data[@Name='SSID']='SSID HERE'] and System[(EventID='8003')]]
</Select></Query></QueryList>"
$Triggers += $EventTrigger
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -StartWhenAvailable
Register-ScheduledTask -Action $Action -Principal $Principal -Trigger $Triggers -Settings $Settings -TaskName $TaskName -Description $TaskDescription -Force

# Original code from Ben N. (https://superuser.com/questions/1168551/turn-on-off-bluetooth-radio-adapter-from-cmd-powershell-in-windows-10/1293303#1293303) adapted for WiFi radio power state management

[CmdletBinding()] Param (
    [Parameter(Mandatory=$False)][ValidateSet('Off', 'On')][string]$RadioStatus,
    [Parameter(Mandatory=$False)][Switch]$Bounce
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

Function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

[Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
[Windows.Devices.Radios.RadioAccessStatus,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
Await ([Windows.Devices.Radios.Radio]::RequestAccessAsync()) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null
$Radios = Await ([Windows.Devices.Radios.Radio]::GetRadiosAsync()) ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]])
$WiFi = $Radios | Where-Object { $_.Kind -eq 'WiFi' }
[Windows.Devices.Radios.RadioState,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null

if ($WiFi.State -ne $RadioStatus -and (!($Bounce))) {
    Write-Host "Current wireless radio power state: $($WiFi.State)"
    Write-Host "Setting radio power state to $RadioStatus" -ForegroundColor Yellow
    Await ($WiFi.SetStateAsync($RadioStatus)) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null
} 

if ($Bounce) {
    Write-Host "Bouncing radio power" -ForegroundColor Yellow
    Await ($WiFi.SetStateAsync("Off")) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null
    Start-Sleep -Seconds 3
    $Radios = Await ([Windows.Devices.Radios.Radio]::GetRadiosAsync()) ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]])
    $WiFi = $Radios | Where-Object { $_.Kind -eq 'WiFi' }
    if ($WiFi.State -eq 'Off') {
        Await ($WiFi.SetStateAsync("On")) ([Windows.Devices.Radios.RadioAccessStatus]) | Out-Null
        } else {
        Write-Host "Radio is already on." -ForegroundColor Yellow
        }
}

exit
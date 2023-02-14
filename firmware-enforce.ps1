# Set the log file path
$logFilePath = "C:\logs\update-unifi-firmware.log"

# Load the firmware versions from the JSON config file
$firmwareVersions = ConvertFrom-Json (Get-Content "C:\configs\firmware-versions.json")

# Load the Unifi Controllers from the JSON config file
$unifiControllers = ConvertFrom-Json (Get-Content "C:\configs\unifi-controllers.json")

# Create a logging function that writes to the log file
function Log-Message {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Message,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$LogLevel
  )

  $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$LogLevel] $Message"
  Add-Content -Path $logFilePath -Value $logEntry
}

# Log an informational message
Log-Message "Starting firmware update process" "INFO"

# Loop through each Unifi Controller
foreach ($unifiController in $unifiControllers) {
  try {
    # Connect to the current Unifi Controller
    $unifiSite = Connect-UnifiController -Url $unifiController.url -Username $unifiController.username -Password $unifiController.password

    # Get a list of all sites for the current Unifi Controller
    $sites = Get-UnifiSite -Site $unifiSite -ListSites

    # Loop through each site and update the firmware for each device
    foreach ($site in $sites) {
      try {
        # Connect to the Unifi Controller for the current site
        Connect-UnifiController -Url $unifiController.url -Username $unifiController.username -Password $unifiController.password -Site $site.Name

        # Get a list of all devices for the current site
        $devices = Get-UnifiDevice -Site $site.Name

        # Loop through each device and update its firmware
        foreach ($device in $devices) {
          # Find the firmware version for the current device model
          $firmwareVersion = $firmwareVersions.$($device.Model)

          # Check if the device needs a firmware update
          if ($firmwareVersion -and $device.Version -ne $firmwareVersion) {
            # Update the device firmware
            Update-UnifiDeviceFirmware -DeviceId $device.Id -FirmwareVersion $firmwareVersion

            # Log a success message
            Log-Message "Updated firmware on $($device.Name) to version $firmwareVersion" "INFO"
          }
        }
      }
      catch {
        # Log an error message for the current site
        Log-Message "Error updating firmware for site $($site.Name): $_" "ERROR"
      }
    }
  }
  catch {
    # Log an error message for the current Unifi Controller
    Log-Message "Error connecting to Unifi Controller at $($unifiController.url): $_" "ERROR"
  }
}

# Log a completion message
Log-Message "Firmware update process completed" "INFO"

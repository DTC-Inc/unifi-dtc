# Load configuration from JSON file
$config = Get-Content "config.json" | ConvertFrom-Json

# Set up logging
$logPath = "password_reset.log"
$logger = New-Object System.IO.StreamWriter($logPath, $false)

# Loop through each controller and reset the user's password
$config.controllers | ForEach-Object {
  $controller = $_
  $controllerUrl = "https://$($controller.host):$($controller.port)"
  $unifiClient = New-Object unifiapi.Controller $controllerUrl, $controller.username, $controller.password, "v5"

  try {
    $unifiClient.login()
    $users = $unifiClient.listUsers()
    $user = $users | Where-Object { $_.name -eq $config.username }
    if ($user) {
      $logger.WriteLine("Resetting password for user $($user.name) on controller $($controller.host)")
      $unifiClient.modifyUser($user.id, @{x_password = $config.newPassword})
    } else {
      $logger.WriteLine("User $($config.username) not found on controller $($controller.host)")
    }
  } catch {
    $logger.WriteLine("Error resetting password on controller $($controller.host): $_")
  } finally {
    $unifiClient.logout()
  }
}

# Close logging
$logger.Dispose()

const unifi = require('unifi-api');
const winston = require('winston');
const config = require('./config.json');

// Set up the logger
const logger = winston.createLogger({
  transports: [
    new winston.transports.File({
      filename: 'update-unifi-firmware.log',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      )
    })
  ]
});

// Define a function to log messages
function logMessage(level, message) {
  logger.log({
    level: level,
    message: message
  });
}

// Loop through each Unifi Controller
for (const controller of config.controllers) {
  // Connect to the current Unifi Controller
  unifi
    .login(controller.url, controller.username, controller.password)
    .then(async (unifi) => {
      // Get a list of all sites for the current Unifi Controller
      const sites = await unifi.listSites();

      // Loop through each site and update the firmware for each device
      for (const site of sites) {
        // Connect to the Unifi Controller for the current site
        await unifi.switchSite(site.name);

        // Get a list of all devices for the current site
        const devices = await unifi.listDevices();

        // Loop through each device and update its firmware
        for (const device of devices) {
          // Find the firmware version for the current device model
          const firmwareVersion = config.firmwareVersions[device.model];

          // Check if the device needs a firmware update
          if (firmwareVersion && device.version !== firmwareVersion) {
            // Update the device firmware
            await unifi.updateDeviceFirmware(device.id, firmwareVersion);

            // Log a success message
            logMessage('info', `Updated firmware on ${device.name} to version ${firmwareVersion}`);
          }
        }
      }
    })
    .catch((err) => {
      // Log an error message for the current Unifi Controller
      logMessage('error', `Error connecting to Unifi Controller at ${controller.url}: ${err}`);
    });
}

// Log a completion message
logMessage('info', 'Firmware update process completed');

const unifi = require('unifi-api');
const fs = require('fs');

// Load configuration from JSON file
const config = JSON.parse(fs.readFileSync('config.json', 'utf8'));

// Loop through each controller and reset the user's password
config.controllers.forEach(controller => {
  const controllerUrl = `https://${controller.host}:${controller.port}`;
  const unifiClient = new unifi.Controller(controllerUrl, controller.username, controller.password, { version: 'v5' });

  unifiClient.login()
    .then(() => {
      return unifiClient.listUsers();
    })
    .then(users => {
      const user = users.find(u => u.name === config.username);
      if (user) {
        console.log(`Resetting password for user ${user.name} on controller ${controller.host}`);
        return unifiClient.modifyUser(user.id, { x_password: config.newPassword });
      } else {
        console.log(`User ${config.username} not found on controller ${controller.host}`);
      }
    })
    .catch(error => {
      console.error(`Error resetting password on controller ${controller.host}: ${error.message}`);
    })
    .finally(() => {
      unifiClient.logout();
    });
});

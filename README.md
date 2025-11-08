# velocity_service_unix
A Unix systemd service setup for Velocity Minecraft proxy.

Velocity is a high-performance proxy server for Minecraft that allows for multiple Java Minecraft servers to be connected and managed 
efficiently, designed for scalability and stability. This setup service has been designed to simplify setting up the reverse proxy.


## Installation

### Method 1
Run the below command

``` bash
curl https://raw.githubusercontent.com/mk5912/velocity_service_unix/refs/heads/main/scripts/install.sh | sudo bash
```
  

### Method 2
Run the below commands:   

``` bash
wget https://raw.githubusercontent.com/mk5912/velocity_service_unix/refs/heads/main/scripts/install.sh
```
then
``` bash
sudo chmod +x install.sh
```
and finish with
``` bash
sudo . install.sh||sudo bash install.sh
```

## Uninstall
To uninstall this service you must run the below commands either as root or with sudo access, the commands must be run in order.
### WARNING running these commands will completely remove the velocity server and it's files, should you wish to keep any config file please navigate the file system to remove only what you don't want or backup to the home directory.

``` bash
systemctl stop velocity
```
then
``` bash
systemctl disable velocity
```
followed by
``` bash
rm -r /etc/velocity /etc/systemd/system/velocity.service
```
with the final command to remove the service fully being
``` bash
systemctl daemon-reload
```

An alternative method is to run the install script with the argument `remove` to completely wipe the service from the system, or `reinstall` to wipe velocity from the system and run the installer straight after, doing this via an SSH session may result in the SSH connection being reset due to the command `systemctl daemon-reload` affecting the SSH service.
  
## Contributing

Pull requests are welcome, but for major changes, please open an issue first to discuss what you would like to change.


## License
[MIT](https://github.com/mk5912/velocity_service_unix/blob/main/LICENSE.txt)



## Authors and Acknowledgements
Daniel Hickey

Alex Kerr

Steve

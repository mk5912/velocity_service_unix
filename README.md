# Branch description
This "DEV" branch is for testing new/ updated features and may not work reliably!
If swapping from the main branch to this Dev branch, please check the uninstall section below.

# velocity_service_unix
A Unix systemd service setup for Velocity Minecraft proxy.

Velocity is a high-performance proxy server for Minecraft that allows for multiple Java Minecraft servers to be connected and managed 
efficiently, designed for scalability and stability. This setup service has been designed to simplify setting up the reverse proxy.


## Installation

### Method 1
Run the below command

   ```
   curl https://raw.githubusercontent.com/mk5912/velocity_service_unix/refs/heads/DEV/scripts/install.sh | sudo bash
   ```
  

### Method 2
Run the below commands:   

   ``` 
   wget https://raw.githubusercontent.com/mk5912/velocity_service_unix/refs/heads/DEV/scripts/install.sh
   ```
then
   ```
   sudo chmod +x install.sh
   ```
and finish with
   ```
   sudo ./install.sh||sudo bash install.sh
   ```

## Uninstall
To uninstall this service you must run the below commands either as root or with sudo access, the commands must be run in order.
### WARNING running these commands will completely remove the velocity server and it's files, should you wish to keep any config file please navigate the file system to remove only what you don't want.

   ```
   systemctl stop velocity
   ```
then
   ```
   systemctl disable velocity
   ```
and finally
   ```
   rm -r /etc/velocity /etc/systemd/system/velocity.service
   ```
  
## Contributing

Pull requests are welcome, but for major changes, please open an issue first to discuss what you would like to change.


## License
[MIT](https://github.com/mk5912/velocity_service_unix/blob/main/LICENSE.txt)



## Authors and Acknowledgements
Daniel Hickey

Alex Kerr

Steve

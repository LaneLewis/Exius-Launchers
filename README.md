# Launching an Exius Server
In order to launch an Exius server, you will need access to some container SaaS platform (AWS Lightsail, Fly.io, digital ocean, etc) or a virtual machine (on AWS EC2, vultr, linode, etc). In my personal opinion, the most streamlined platform to use is Fly.io. This guide will go through setting up an Exius server using the container service Fly.io and on a virtual machine (loosely tailored to AWS). The documentation for Rclone can be found [here](https://rclone.org/install/) and fly.io can be found [here](https://fly.io/docs/getting-started/installing-flyctl/).

## Quick Setup on Linux/Mac using Fly.io
First clone this repository onto your local machine and place your current
directory inside it:
```shell
git clone https://github.com/LaneLewis/Exius-Launchers
cd ./Exius-Launchers
```
Download Rclone on your local machine:
```shell
curl https://rclone.org/install.sh | sudo sh
```
run
```shell
rclone config
```
and create a new one for your chosen cloud storage provider (generally choosing just the defaults is fine).
Then copy the rclone config into the Exius-Launchers directory.
```shell
str=($(rclone config file));loc=${str[5]};cp $loc ./rclone.conf;
```
This app can be setup on fly.io within the free tier for 0$/month.

For a streamlined install on Linux/Mac run:
```shell
    ./exius-cli.sh install_fly
```
Then continue the setup process by [signing up](https://fly.io/docs/getting-started/log-in-to-fly/) through the command line interface.

Then start the process of launching on fly.io
```shell
fly launch --remote-only
```

When prompted, create a unique name for your app. Then when asked if you want to create and attatch a Postgres instance press yes. The creation of the postgres instance will take a little while. After the postgres instance is created, you will be asked if you want to launch the app now. You should press no.

Then go into the created fly.toml file and add the environmnent variables for ADMIN_KEY and CONFIGNAME replacing the values with your own. So, the env section will look something like:
```
[env]
  ADMINKEY = "your-key"
  CONFIGNAME = "your-rclone-remote-name"
```

Then deploy the app
```shell
fly deploy --remote-only
```

After waiting for it to finish deploying, you should be all set! To check on the instance, you can view the logs by 
```shell
fly logs
```
Information on other operations you can do can be found at the [fly docs](https://fly.io/docs/flyctl/).
### Debugging on Fly.io
One of the most common (hopefully rare) issues you might run across is expiring rclone configs. If you look at the fly logs and see this happening, you can rebuild the container using a script in exius-cli.sh. Run :
```shell
./exius-cli.sh fly_redeploy_exius [your rclone remote name]
```
This will create open a web browser window to authenticate again to the remote. After authenticating, it will redeploy the Exius app.

## Quick Setup on linux/mac for Non-https Enabled VM
For the quick setup, you will need a pem file for ssh-ing onto the server and a class A subdomain on the ipv4 address of the web server. Ports 443, 80, and 22 will need to be open on this server. The defaults for several functions are using the linux AMI 2 machine on AWS, however other VMs can be used by passing flags to a couple functions.

To begin, clone the Exius-Launchers repository into a local directory and move into the repository.
```shell
git clone https://github.com/LaneLewis/Exius-Launchers
cd ./Exius-Launchers
```
Then go in and replace the following environment variables of docker-compose-https.yml with your own:
    CONFIGNAME: the name of your created rclone remote
    ADMINKEY: a 64 character string of letters/numbers to have full access to manipulating the cloud storage remote.
    VIRTUAL_HOST: the subdomain that you pointed at the server's ip4 address
    LETSENCRYPT_HOST: the subdomain that you pointed at the server's ip4 address
    LETSENCRYPT_EMAIL: an email to use for lets-encrypt verification and warnings.
Download Rclone on your local machine:
```shell
curl https://rclone.org/install.sh | sudo sh
```
run
```shell
rclone config
```
and create a new one for your chosen cloud storage provider (generally choosing just the defaults is fine). Then run the following with optional flags:
```shell
./exius-cli.sh vm_exius_up [your-pem-file-path] [your-dns] -u <user for ssh, defaults to ec2-user> -p <package manager, default yum>
```
This will go into the VM, download docker etc and get the docker compose containers up and going with a free lets-encrypt https certificate. At this point, assuming everything installs correctly, your personal exius server is up and going! 
# Bug Fixing
Just like in fly.io, the most likely error you will recieve is if an Rclone refresh token fails to renew properly. To reboot the containers (don't worry you won't lose any information) with an updated rclone config or modified envs in docker-compose-https, run:
```shell
./exius-cli.sh vm_exius_redeploy [your-pem-file-path] [your-dns] -u <user for ssh, defaults to ec2-user> -p <package manager, default yum>
```
If you need to view the server logs, the easiest way is to ssh into the server and run 
```docker-compose logs```

## General Setup on a Web Server
Once again make sure you are in the Exius-Launchers repository directory on your local machine. You will need a pem key file for ssh-ing onto the server and the dns of the server. In addition, if https is not enabled, you will need a class A subdomain name on your server's ip4 address (you can get these for free if you need to).

On the remote machine, make sure ports 443 and 80 are open. Next copy the rclone file into the local directory
```shell
str=($(rclone config file));loc=${str[5]};cp $loc ./rclone.conf;
```
If the web server has https enabled already, the docker-compose file you will need is docker-compose.yml. If not (they typically do not) you will need the docker-compose-https.yml file. In your chosen docker-compose file, replace the environment variable values with your own.

Next, use scp to place the Dockerfile, docker-compose.yml, docker-compose-https.yml, and rclone.conf inside of the remote machine.

If not already installed, you will need to [install docker](https://docs.docker.com/engine/install/ubuntu/) and docker compose into the remote machine. 
Then, if https is enabled, run 
```shell
docker compose up
 ```

If https is not enabled run 
```shell
 docker compose -f docker-compose-https.yml up
 ```

At this point your apps should be running and https should be enabled!

## Setting Up a Cloud Storage Provider With Rclone
If you wish to not connect to an external cloud storage provider, and instead use the data folder on the server make an alias type remote to 
```
/app/data
```
This data will persist across multiple reboots of the container, but not the closing down of the virtual machine itself. 

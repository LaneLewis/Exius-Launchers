# Launching an Exius Server
In order to launch an Exius server, you will need access to some container SaaS platform (AWS Lightsail, Fly.io, etc) or a virtual machine (on AWS, vultr, linode, etc). In my personal opinion, the most streamlined platform to use is Fly.io. This guide will go through setting up an Exius server using the container service Fly.io and on an AWS virtual machine.  
## Setting Up a Cloud Storage Provider With Rclone
If you wish to not connect to an external cloud storage provider, and instead use the data folder on the server, you may skip the rclone steps.

Otherwise, to begin, you will need Rclone installed on your local computer to generate a config file that will connect into your cloud storage. To install Rclone visit the [Rclone Docs](https://rclone.org/install/).

Then on your local machine run 
`rclone config`
and select n) to create a new remote. Then follow the prompts to select your storage and create create an authentication token for it. Make sure to remember the name of the new remote, you will need this later!
now, locate your rclone config file using: 
`rclone config file`
## Setup on Fly.io
This app can be setup on fly.io within the free tier for 0$/month.

To begin download the fly command line tool at [fly install](https://fly.io/docs/getting-started/installing-flyctl/) and then [sign up](https://fly.io/docs/getting-started/log-in-to-fly/) through the command line interface.

After setting up fly, clone this repository onto your local machine:
`git clone https://github.com/LaneLewis/Exius-Launchers`

Make sure your current directory is inside of the Exius-Launchers repository. Then copy the rclone config into the directory.
`str=($(rclone config file));loc=${str[5]};cp $loc ./rclone.conf;`

Then start the process of launching on fly.io
`fly launch --remote-only`

When prompted create a unique name for your app. Then when prompted if you want to create and attatch a Postgres instance press yes. The creation of the postgres instance will take a little while. After the postgres instance is created, you will be asked if you want to launch the app now. You should press no.

Then go into the created fly.toml file and add the environmnent variables for ADMIN_KEY and CONFIGNAME replacing the values with your own. So, the env section will look something like:
```
[env]
  ADMINKEY = "your-key"
  CONFIGNAME = "your-rclone-remote-name"
```

Then deploy the app
`fly deploy --remote-only`

After waiting for it to deploy, you should be all set! To check on the instance, you can view the logs by 
`fly logs`
Information on other operations you can do can be found at the [fly docs](https://fly.io/docs/flyctl/).
### Debugging on Fly.io
One of the most common (hopefully rare) issues you might run across is expiring rclone configs. If you look at the fly logs and see this happening, you can rebuild the container using the script in rebuild.sh. Then run:
`rebuild.sh redeploy your-rclone-remote-name`
This will create open a web browser window to authenticate again to the remote. After authenticating, it will redeploy the Exius app.
## Setup on a Web Server
Once again make sure you are in the Exius-Launchers repostiory directory on your local machine. 

On the remote machine, make sure ports 443 and 80 are open. Next copy the rclone file into the local directory
`str=($(rclone config file));loc=${str[5]};cp $loc ./rclone.conf;`
If the web server has https enabled already, the docker-compose file you will need is docker-compose.yml. If not (they typically do not) you will need the docker-compose-https.yml file. In addition, if https is not enabled, you will need to purchase a domain and attach a subdomain to your remote server. In your chosen docker-compose file, replace the environment variable values with your own. 

Next, use scp to place the Dockerfile, docker-compose.yml, docker-compose-https.yml, and rclone.conf inside of the remote machine.

If not already installed, you will need to [install docker](https://docs.docker.com/engine/install/ubuntu/) into the remote machine. Assuming ubuntu linux, it will look like:
` sudo apt-get update
 $ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
 `.
Then, if https is not enabled, run 
`docker compose build
 docker compose up`

If https is enabled run 
`docker compose -f docker-compose-https.yml build
 docker compose -f docker-compose-https.yml up`

At this point your apps should be running and https should be enabled!

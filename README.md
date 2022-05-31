# Launching an Exius Server
If you wish to not connect to an external cloud storage provider, and instead use the data folder on the server, you may skip the rclone steps.

Otherwise, to begin, you will need Rclone installed on your local computer to generate a config file that will connect into your cloud storage. To install Rclone visit the [Rclone Docs](https://rclone.org/install/).

Then on your local machine run 
`rclone config`
and select n) to create a new remote. Then follow the prompts to select your storage and create create an authentication token for it. Make sure to remember the name of the new remote, you will need this later!
now, locate your rclone config file using: 
`rclone config file`
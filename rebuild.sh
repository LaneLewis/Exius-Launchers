#!/bin/sh
function redeploy(){
    remote=$1
    echo $(rclone config update $remote)
    str=($(rclone config file));loc=${str[5]};cp $loc ./rclone.conf;
    echo $(fly deploy --remote-only)
}
function deploy(){
    str=($(rclone config file));loc=${str[5]};cp $loc ./rclone.conf;
    echo $(fly launch --remote-only)
}
function install(){
    echo $(curl https://rclone.org/install.sh | sudo sh)
    echo $(curl -L https://fly.io/install.sh | sudo sh)
}
"$@"
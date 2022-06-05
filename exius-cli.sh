#!/bin/sh

set -e

#redeploys exius on fly.io, needs an rclone remote name to renew
fly_redeploy_exius()
{
    remote=$1
    echo $(rclone config update $remote)
    str=($(rclone config file));loc=${str[5]};cp $loc ./rclone.conf;
    echo $(fly deploy --remote-only)
}

#installs flyctl and adds it to the user's bash profile
install_fly()
{
    echo $(curl -L https://fly.io/install.sh | sh)
    echo '#fly.io commands' >> ~/.bash_profile
    echo 'export FLYCTL_INSTALL=$HOME/.fly' >> ~/.bash_profile
    echo 'export PATH="$FLYCTL_INSTALL/bin:$PATH"'>> ~/.bash_profile
}

# installs docker on machine, needs a package manager name passed in
vm_docker_install()
{
    pkg=$1
    sudo $pkg install docker -y;sudo usermod -a -G docker ec2-user;id ec2-user;sudo systemctl enable docker.service;sudo systemctl start docker.service;
    wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
    sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
    sudo chmod -v +x /usr/local/bin/docker-compose
}

#goes into a server and installs docker/docker-compose, copies in an rclone config, and starts the containers.
# requires a path to the server pem file, the dns of the server, and optional flags for the user to use
# as well as the package manager of the linux instance. 
vm_exius_up()
{
    function help(){
        echo "USAGE: aws_docker pem-file-path dns -u <ssh user, default ec2-user> -p <package manager, default yum> -h"
    }
    pem=$1
    dns=$2
    u=ec2-user
    p=yum
    while getopts "hu:p:" ARG; do
        case "$ARG" in
            u) echo "running user to $OPTARG";
                u=$OPTARG;;
            p) echo "running package manager to $OPTARG";
                p=$OPTARG;;
            h) help;
               exit;;
        esac
    done
    if [ $# -eq 0 ] || [ $# -eq 1 ] ; then
        echo 'both the arguments pem-file-path and dns are required\n for help run "vm_docker -h"'
        exit 0
    fi
    echo $(ssh -i $pem $u@$dns "mkdir -p ~/rclone/")
    echo $(ssh -i $pem $u@$dns "$(typeset -f vm_docker_install);vm_docker_install $p")
    echo $(scp -i $pem docker-compose-https.yml $u@$dns:)
    str=($(rclone config file));loc=${str[5]};echo scp -i $pem $loc $u@$dns:~/rclone/rclone.conf
    echo $(ssh -i $pem $u@$dns "docker-compose -f docker-compose-https.yml up")
}

#renews an rclone remote with a web browser prompt, then copies the new config and the local http compose file
#into the container and restarts the containers. requires a path to the server pem file, the dns of the server, and optional flags for the user to use
# as well as the package manager of the linux instance. 
vm_exius_redeploy()
{
    pem=$1
    dns=$2
    u=ec2-user
    p=yum
    r=data
    while getopts "hu:p:r:" ARG; do
        case "$ARG" in
            u) echo "running user to $OPTARG";
                u=$OPTARG;;
            p) echo "running package manager to $OPTARG";
                p=$OPTARG;;
            r) echo "running remote as $OPTARG";
                r=$OPTARG;;
            h) help;
               exit;;
        esac
    done
    if [ $# -eq 0 ] || [ $# -eq 1 ] ; then
        echo 'both the arguments pem-file-path and dns are required\n for help run "aws_docker -h"'
        exit 0
    fi
    rclone config update $r && echo "successfully updated config"
    ssh -i $pem $u@$dns "mkdir -p ~/rclone/;sudo chown $u ~/rclone/" && echo "created rclone directory in vm"
    scp -i $pem docker-compose-https.yml $u@$dns: && echo "copied local https compose to vm"
    str=($(rclone config file));loc=${str[5]};scp -i $pem $loc $u@$dns:~/rclone && echo "copied rclone config to vm"
    echo "rebooting exius containers"
    echo $(ssh -i $pem $u@$dns "docker-compose -f docker-compose-https.yml down;docker-compose -f docker-compose-https.yml up -d")
}
"$@"
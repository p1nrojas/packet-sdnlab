#!/bin/sh

#Install docker
echo "$(date) Installing Nuage VSP at packet.net (git.hub/p1nrojas)" > /tmp/install.log
echo "$(date) Installing dockers..."
curl -fsSL https://get.docker.com/ | sh >> /tmp/install.log
systemctl start docker >> /tmp/install.log
systemctl enable docker >> /tmp/install.log

#Create container images
echo "$(date) Creating containers..."
mkdir -p ~/github/packet-sdnlab >> /tmp/install.log
cd ~/github/packet-sdnlab >> /tmp/install.log
curl -fsS -o Dockerfile https://raw.githubusercontent.com/p1nrojas/packet-sdnlab/master/install/Dockerfile >> /tmp/install.log
curl -fsS -o vimrc https://raw.githubusercontent.com/p1nrojas/packet-sdnlab/master/install/vimrc >> /tmp/install.log
curl -fsS -o bash_profile https://raw.githubusercontent.com/p1nrojas/packet-sdnlab/master/install/bash_profile >> /tmp/install.log
curl -fsS -o setup.sh https://raw.githubusercontent.com/p1nrojas/packet-sdnlab/master/install/setup.sh >> /tmp/install.log

#Asking packet.net token
echo ">>"
echo ">>"
echo -n "Enter packet.net token (i.e MaKWKw8AxUASBTE7JKj1y7eM7qW4o9Sd ) and press [ENTER]: "
read packet_token
if [[ $packet_token =~ ^[A-Za-z0-9]{32}$ ]]; then echo $packet_token > .packet_token; else echo "Format isn't right, bye!"; exit 1; fi

#Asking packet.net project id
echo ">>"
echo ">>"
echo -n "Enter packet.net project ID (i.e. bed437ce-6ae7-6b3a-a8e0-163e13a12a32 ) and press [ENTER]: "
read project_id
if [[ $project_id =~ ^[a-z0-9]*-[a-z0-9]*-[a-z0-9]*-[a-z0-9]*-[a-z0-9]*$ ]]; then echo $project_id > .packet_project_id; else echo "Format isn't right, bye!"; exit 1; fi

echo ">>"
echo ">>"
echo -n "Enter VSD license code ( warning: remove line breaks and spaces ) and press [ENTER]: "
read nuage_license_key
if [[ $nuage_license_key =~ \ + ]]; then echo "Format isn't right, bye!"; else echo $nuage_license_key > .nuage_license_key; fi

echo "$(date) Passed. Creating container image..."

docker build -t p1nrojas/packet-sdnlab . >> /tmp/install.log

#Create data-only container
echo "$(date) Creating data-only container..."
docker run -d --name vns-data-only p1nrojas/packet-sdnlab true

echo "$(date) loading app files..."
docker run -d -i -t --volumes-from vns-data-only --name vns-packet p1nrojas/packet-sdnlab

exit 0
sleep 30

echo "$(date) Copying public key to ansible..."
docker cp vns-data-only:/home/dev/.ssh/id_rsa.pub .
cat id_rsa.pub >> ~/.ssh/authorized_keys ; rm -f id_rsa.pub

echo "$(date) Creating bare_metal server and preparing weave..."
docker run --rm --volumes-from vns-data-only p1nrojas/packet-sdnlab /home/dev/packet-sdnlab/packet.sh

echo "$(date) Installing Nuage VNS..."
docker run --rm --volumes-from vns-data-only --network weave --ip 192.168.0.101 p1nrojas/packet-sdnlab /home/dev/packet-sdnlab/nuage.sh

echo
echo
echo "================================================"
echo "Summary Results"
docker run --rm --volumes-from vns-data-only p1nrojas/packet-sdnlab cat /home/dev/packet-sdnlab/.summary

echo "$(date) done!"

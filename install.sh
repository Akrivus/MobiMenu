#!/bin/sh

echo 'Updating your packages...'
sudo apt update && sudo apt upgrade -y
echo 'Installing nginx and FIM...'
sudo apt install nginx fim
echo 'Configuring nginx...'
sudo cp -f ./nginx.config /etc/nginx/sites-enabled/default
echo 'Appending start up script to your bash profile.'
echo 'cd /home/pi/MobiMenu/ && bundle exec ruby server.rb' >> ~/.profile
echo 'Please configure your Pi to automatically log in.'
sudo raspi-config
echo 'Rebooting Pi...'
sudo reboot
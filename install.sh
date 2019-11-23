#!/bin/sh

echo 'Updating your packages...'
sudo apt update && sudo apt upgrade -y
echo 'Installing nginx...'
sudo apt install nginx
echo 'Configuring nginx...'
sudo cp -f ./nginx.config /etc/nginx/sites-enabled/default
echo 'Appending start up script to your bash profile.'
echo 'bundle exec ruby ~/MobiMenu/server.rb' >> ~/.profile
echo 'Please configure your Pi to automatically log in.'
sudo raspi-config
echo 'Rebooting Pi...'
sudo reboot
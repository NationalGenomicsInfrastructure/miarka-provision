#!/bin/bash
sudo yum install epel-release -y
sudo yum group install "Development Tools" -y
sudo yum install python-pip vim python-devel -y
sudo pip install virtualenv
sudo pip install backports.ssl_match_hostname
sudo pip install ansible

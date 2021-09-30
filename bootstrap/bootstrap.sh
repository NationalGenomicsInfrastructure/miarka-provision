#!/bin/bash

set -x 

# Minimalistic and hard coded script for bootstrapping the Ansible environment on irma3

if [ -d /lupus/ngi/irma3/deploy ] ; then
	echo "Irma provisioning repo already exists, so the irma3 environment is probably already setup properly. Aborting."
	exit 1
fi

umask 0002

mkdir -p /lupus/ngi/irma3/
chgrp ngi-sw /lupus/ngi/irma3
chmod g+rwXs /lupus/ngi/irma3

echo "Cloning the Irma provisioning repo" 
git clone https://github.com/NationalGenomicsInfrastructure/irma-provision /lupus/ngi/irma3/deploy

mkdir -p /lupus/ngi/irma3/devel/
mkdir -p /lupus/ngi/irma3/log/

echo "Copying environment bashrc file" 
cp /lupus/ngi/irma3/deploy/bootstrap/bashrc /lupus/ngi/irma3/bashrc

echo "Downloading Python virtualenv" 
curl -o /lupus/ngi/irma3/virtualenv-15.0.0.tar.gz https://pypi.python.org/packages/source/v/virtualenv/virtualenv-15.0.0.tar.gz 

cd /lupus/ngi/irma3 && tar xfz virtualenv-15.0.0.tar.gz

echo "Setting up a virtual environment for Ansible"
/lupus/ngi/irma3/virtualenv-15.0.0/virtualenv.py -p /usr/bin/python2.7 /lupus/ngi/irma3/ansible-env

/lupus/ngi/irma3/ansible-env/bin/activate

echo "Installing Ansible into virtual environment"
pip install ansible

echo "Installing pexpect for syncing functionality into the cluster"
pip install pexpect

echo "Installing cpanm so we can install Perl packages locally"
cd /lupus/ngi/irma3/ansible-env/bin
curl -L https://cpanmin.us -o cpanm
chmod +x ./cpanm

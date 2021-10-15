#!/bin/bash

set -x
set -e

# Minimalistic and hard coded script for bootstrapping the Ansible environment on miarka3
PROVISIONURL=https://github.com/NationalGenomicsInfrastructure/miarka-provision/archive/refs/heads
PROVISIONBRANCH=devel
VIRTUALENVURL=https://pypi.python.org/packages/source/v/virtualenv
VIRTUALENVVERSION=20.8.1
REPOPATH="$HOME/vulpes/ngi/miarka3"

if [ -d  "$REPOPATH/deploy" ] ; then
        echo "Miarka provisioning repo already exists, so the miarka3 environment is probably already setup properly. Aborting."
        exit 1
fi

umask 0002

mkdir -p $REPOPATH/
chgrp ngi-sw $REPOPATH
chmod g+rwXs $REPOPATH

echo "Cloning the Miarka provisioning repo"
ZIPNAME="miarka-provision-${PROVISIONBRANCH}"
curl -L -o "$REPOPATH/${ZIPNAME}.zip" "$PROVISIONURL/${PROVISIONBRANCH}.zip"
unzip -d $REPOPATH "$REPOPATH/${ZIPNAME}.zip"
mv "$REPOPATH/${ZIPNAME}" $REPOPATH/deploy

mkdir -p $REPOPATH/devel/
mkdir -p $REPOPATH/log/

echo "Copying environment bashrc file"
cp $REPOPATH/deploy/bootstrap/bashrc $REPOPATH/bashrc

echo "Setting up a venv for Ansible"
/usr/bin/python3 -m venv "$REPOPATH/ansible-env"
source "$REPOPATH/ansible-env/bin/activate"
pip install --upgrade pip

echo "Installing Ansible into virtual environment"
pip install ansible

echo "Installing pexpect for syncing functionality into the cluster"
pip install pexpect

echo "Installing cpanm so we can install Perl packages locally"
cd $REPOPATH/ansible-env/bin
curl -L https://cpanmin.us -o cpanm
chmod +x ./cpanm

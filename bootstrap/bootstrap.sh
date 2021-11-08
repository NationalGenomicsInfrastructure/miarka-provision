#!/bin/bash

set -x
set -e

# Minimalistic and hard coded script for bootstrapping the Ansible environment on miarka3
PROVISIONREPO="miarka-provision"
PROVISIONURL="https://github.com/NationalGenomicsInfrastructure/${PROVISIONREPO}.git"
PROVISIONBRANCH="devel"

# Use a global environmental variable for the deploy root path
if [ -z "$DEPLOYROOT" ] ; then
  echo "The global environment variable DEPLOYROOT needs to be set to the path under which deployments will be made. Aborting"
  exit 1
fi

if [ -d  "$DEPLOYROOT/$PROVISIONREPO" ] ; then
    echo "Miarka provisioning repo already exists, so the environment is probably already setup properly. Aborting."
    exit 1
fi

umask 0002

mkdir -p "$DEPLOYROOT"
chgrp ngi-sw "$DEPLOYROOT"
chmod g+rwXs "$DEPLOYROOT"

ORIGIN="$(pwd)"
cd "$DEPLOYROOT"

echo "Cloning the Miarka provisioning repo"
git clone "$PROVISIONURL"
cd ${PROVISIONREPO}
git checkout "$PROVISIONBRANCH"
cd ..

echo "Copying environment bashrc file"
sed -re "s#__DEPLOYROOT__#$DEPLOYROOT#" "${PROVISIONREPO}/bootstrap/bashrc" > "$DEPLOYROOT/bashrc"

echo "Setting up a venv for Ansible"
/usr/bin/python3 -m venv "ansible-env"
source "ansible-env/bin/activate"
pip install --upgrade pip

echo "Installing Ansible into virtual environment"
pip install ansible

echo "Installing pexpect for syncing functionality into the cluster"
pip install pexpect

echo "Installing cpanm so we can install Perl packages locally"
cd ansible-env/bin
curl -L https://cpanmin.us -o cpanm
chmod +x ./cpanm

cd "$ORIGIN"

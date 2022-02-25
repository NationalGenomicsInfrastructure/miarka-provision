#! /bin/bash

set -e

# Minimalistic and hard coded script for bootstrapping the Ansible environment on miarka3
PROVISIONREPO="miarka-provision"
PROVISIONURL="https://github.com/NationalGenomicsInfrastructure/${PROVISIONREPO}.git"
PROVISIONBRANCH="devel"

# Use a specified root folder for bootstrapping, or default to /vulpes/ngi/deploy
DEFAULTROOT="/vulpes/ngi/deploy"
DEPLOYROOT="$1"
if [ -z "$DEPLOYROOT" ] ; then
  DEPLOYROOT="$DEFAULTROOT"
  echo "A root folder for deployment was not specified, will use $DEPLOYROOT"
fi

if [ -d  "$DEPLOYROOT/$PROVISIONREPO" ] ; then
    echo "Miarka provisioning repo already exists, so the environment is probably already setup properly. Aborting."
    exit 1
fi

umask 0002

mkdir -p "$DEPLOYROOT"
chgrp ngi-sw "$DEPLOYROOT"
chmod g+rwXs "$DEPLOYROOT"

echo "Cloning the Miarka provisioning repo"
git clone -b "$PROVISIONBRANCH" "$PROVISIONURL" "${DEPLOYROOT}/${PROVISIONREPO}"

echo "Set up the repo"
bash "${PROVISIONREPO}/bootstrap/setup_repo.sh" "${DEPLOYROOT}/${PROVISIONREPO}"

ORIGIN="$(pwd)"
cd "$DEPLOYROOT"

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

echo "Installing click, for local python script"
pip install click

echo "Installing requests, for local python script"
pip install requests

cd "$ORIGIN"

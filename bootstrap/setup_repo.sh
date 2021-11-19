#! /bin/bash

###
# This script will clone this repo and setup some necessary files and paths
#

set -x
set -e

REPO_PATH="$1"

DEPLOYROOT="$(dirname "$REPO_PATH")"
PROVISIONREPO="$(basename "$REPO_PATH")"

echo "Bootstrap a log directory"
mkdir -p "$DEPLOYROOT/log"

echo "Copying environment bashrc file"
cp "$DEPLOYROOT/${PROVISIONREPO}/bootstrap/bashrc" "$DEPLOYROOT/bashrc"

echo "Set up required files"
bash "$DEPLOYROOT/${PROVISIONREPO}/bootstrap/setup_required_files.sh" "$DEPLOYROOT/${PROVISIONREPO}" "${DEPLOYROOT}/files"

#! /bin/bash

###
# This script will distribute the required credentials files from a central location to the repo this script is run
# from. If the file does not exist in the designated central location (which can be empty), a dummy file will be
# created instead. This is useful for testing when you don't want the playbook to choke because of missing files.

set -x
set -e

PATH_TO_REPO="$1"
PATH_TO_FILES="$2"

function setup_path {
  mkdir -p "$1"
}

function setup_file {
  f="$1"
  shift
  d="$1"
  shift

  setup_path "$d"
  if [[ -e "$PATH_TO_FILES/$f" ]]
  then
    ln -s "$PATH_TO_FILES/$f" "$d/$f"
  else
    for var in $@
    do
      echo "$var: " >> "$d/$f"
    done
  fi
}

TACA_ROLE_PATH="$PATH_TO_REPO/roles/taca/files"
NGI_PIPELINE_ROLE_PATH="$PATH_TO_REPO/roles/ngi_pipeline/files"
HOST_VARS_PATH="$PATH_TO_REPO/host_vars/127.0.0.1"
TARZAN_ROLE_PATH="$PATH_TO_REPO/roles/tarzan/files"

setup_file "pontus.larsson_medsci.uu.se.key" "$NGI_PIPELINE_ROLE_PATH"

TACA_FILES=("statusdb_creds_stage.yml" "snic_credentials_sthlm.yml" "orderportal_credentials.yml")
for f in "${TACA_FILES[@]}"
do
  setup_file "$f" "$TACA_ROLE_PATH"
done

TARZAN_FILES=("tarzan_cert.pem" "tarzan_key.pem")
for f in "${TARZAN_FILES[@]}"
do
  setup_file "$f" "$TARZAN_ROLE_PATH"
done

# Charon variables expected to be present in the credentials file
CHARON_VARS=""
for var_name in "charon_base_url" "charon_api_token"
do
  for env in "prod" "stage"
  do
    if [[ "$var_name" == "charon_base_url" ]]
    then
      CHARON_VARS="$CHARON_VARS ${var_name}_${env}"
    else
      for site in "upps" "sthlm"
      do
        CHARON_VARS="$CHARON_VARS ${var_name}_${site}_${env}"
      done
    fi
  done
done
setup_file "charon_credentials.yml" "$HOST_VARS_PATH" $CHARON_VARS

MEGAQC_VARS="megaqc_token_upps megaqc_token_sthlm_stage"
setup_file "megaqc_token.yml" "$HOST_VARS_PATH" $MEGAQC_VARS

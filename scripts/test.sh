#!/bin/bash

# check if an argument is present fail if not and display error message
if [ -z "$1" ]; then
  echo "Please supply a rails application directory to test"
  exit 1
fi

app_name=$(basename $1)

export AZURE_ENV_NAME="test-001"
export AZURE_LOCATION="francecentral"
export AZURE_SUBSCRIPTION_ID=$(az account show --output tsv --query id)

rm -rf test-starter && true
mkdir test-starter
cd test-starter
azd init -t dbroeglin/azure-rails-starter
rm -rf ./src
rsync -av $1/ ./src/ --exclude .git


SERVICE_RAILS_DATABASE_NAME="${app_name}_production" \
SECRET_KEY_BASE=$(src/bin/rails secret) \
RAILS_MASTER_KEY="$(cat src/config/master.key)" \
azd up
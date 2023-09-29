#! /bin/bash

timestamp=$(TZ='UTC' date +"%Y%m%d_%H%M%S") # Deployment timestamp. Default is UTC
resourcegroup=ts1-testing-dev-rg

# deploy
az deployment group create \
--name eTAS_deployment_${timestamp} \
--resource-group $resourcegroup \
--template-file resources/main.bicep \
--parameters resources/params.json \
--output table \
--no-wait
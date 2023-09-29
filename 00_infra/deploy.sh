#! /bin/bash

timestamp=$(TZ='UTC' date +"%Y%m%d_%H%M%S") # Deployment timestamp. Default is UTC
location=australiaeast

# deploy
az deployment sub create \
--name eTAS_deployment_${timestamp} \
--location $location \
--template-file resources/main.bicep \
--parameters resources/params.json \
--output table \
--no-wait

#!/bin/bash

# get params
. 'params.sh'

echo Subscription = $sub
echo Resource group = $rg

assignee_df=$(az ad sp list --display-name "$resource_df" -o tsv --query "[].id")
assignee_synapse=$(az ad sp list --display-name "$resource_synapse" -o tsv --query "[].id")

echo Data Factory is $resource_df with ID $assignee_df
echo Synapse is $resource_synapse with ID $assignee_synapse

# assign permissions to storage accounts
for account in "${storage_accounts[@]}"; do
 az role assignment create --assignee "$assignee_df" --role "$storage_role" --scope /subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.Storage/storageAccounts/$account
 az role assignment create --assignee "$assignee_synapse" --role "$storage_role" --scope /subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.Storage/storageAccounts/$account
done

# generate sql to run in control db
cp controldb.sql controldb_${resource_df}.sql && sed -i "s/data_factory/${resource_df}/g" controldb_${resource_df}.sql

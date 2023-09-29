#! /bin/bash

sub=5fc02796-c448-4082-9e29-aaf024a8d9ed # subscription
rg=ts1-testing-dev-rg # resource group

resource_df=ts1-testing-dev-ingest-datafactory1 # data factory
resource_synapse=ts1-testing-dev-synapse1 # synapse

storage_accounts=(ts1testingdevraw1 ts1testingdevcur1) # storage accounts
storage_role="Storage Blob Data Contributor" # storage account roles

# export values
export sub rg resource_df resource_synapse storage_accounts storage_role

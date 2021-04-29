#!/bin/bash

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

az login -u $1 -p $2
az account set --subscription "c0f06edc-2ea7-4dfa-b9de-7536b27fcbfa"

sudo apt update
sudo apt install cifs-utils

resourceGroupName=$3
storageAccountName=$4
fileShareName=$5

mntPath="file-share-mount/"

sudo mkdir -p $mntPath

httpEndpoint=$(az storage account show \
    --resource-group $resourceGroupName \
    --name $storageAccountName \
    --query "primaryEndpoints.file" | tr -d '"')
smbPath=$(echo $httpEndpoint | cut -c7-$(expr length $httpEndpoint))$fileShareName

storageAccountKey=$(az storage account keys list \
    --resource-group $resourceGroupName \
    --account-name $storageAccountName \
    --query "[0].value" | tr -d '"')

sudo mount -t cifs $smbPath $mntPath -o vers=3.0,username=$storageAccountName,password=$storageAccountKey,serverino

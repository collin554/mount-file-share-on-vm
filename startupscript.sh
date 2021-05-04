#!/bin/bash

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash


sudo apt update
sudo apt install cifs-utils

resourceGroupName=$4
storageAccountName=$5
fileShareName=$6
sftpUserName=$7
sftpUserPW=$8

az login -u $1 -p $2
az account set --subscription $3

httpEndpoint=$(az storage account show \
    --resource-group $resourceGroupName \
    --name $storageAccountName \
    --query "primaryEndpoints.file" | tr -d '"')
smbPath=$(echo $httpEndpoint | cut -c7-$(expr length $httpEndpoint))$fileShareName

storageAccountKey=$(az storage account keys list \
    --resource-group $resourceGroupName \
    --account-name $storageAccountName \
    --query "[0].value" | tr -d '"')

sudo adduser $sftpUserName --gecos ",,," --disabled-password
echo "$sftpUserName:$sftpUserPW" | sudo chpasswd

sudo mkdir -p /home/sftp/uploads
sudo chown root:root /home/sftp
sudo chmod 755 /home/sftp
sudo chown $sfptUserName:$sftpUserName /home/sftp/uploads

echo "Match User $sftpUserName" | sudo tee -a /etc/ssh/sshd_config
echo "ForceCommand internal-sftp" | sudo tee -a /etc/ssh/sshd_config
echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
echo "ChrootDirectory /home/sftp" | sudo tee -a /etc/ssh/sshd_config
echo "PermitTunnel no" | sudo tee -a /etc/ssh/sshd_config
echo "AllowAgentForwarding no" | sudo tee -a /etc/ssh/sshd_config
echo "AllowTcpForwarding no" | sudo tee -a /etc/ssh/sshd_config
echo "X11Forwarding no" | sudo tee -a /etc/ssh/sshd_config

sudo systemctl restart sshd

sudo mount -t cifs $smbPath /home/sftp/uploads -o vers=3.0,username=$storageAccountName,password=$storageAccountKey,uid=$(id -u $sftpUserName),gid=$(id -g $sftpUserName),serverino

#!/bin/bash

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

wait

az login -u $1 -p $2
wait
az account set --subscription $3

sudo apt update
wait
sudo apt install cifs-utils
wait

resourceGroupName=$4
wait
storageAccountName=$5
wait
fileShareName=$6
wait
sftpUserName=$7
wait
sftpUserPW=$8
wait


httpEndpoint=$(az storage account show \
    --resource-group $resourceGroupName \
    --name $storageAccountName \
    --query "primaryEndpoints.file" | tr -d '"')
smbPath=$(echo $httpEndpoint | cut -c7-$(expr length $httpEndpoint))$fileShareName
wait

storageAccountKey=$(az storage account keys list \
    --resource-group $resourceGroupName \
    --account-name $storageAccountName \
    --query "[0].value" | tr -d '"')

wait
sudo adduser $sftpUserName --gecos ",,," --disabled-password
wait
echo "$sftpUserName:$sftpUserPW" | sudo chpasswd
wait

sudo mkdir -p /home/sftp/uploads
wait
sudo chown root:root /home/sftp
wait
sudo chmod 755 /home/sftp
wait
sudo chown $sfptUserName:$sftpUserName /home/sftp/uploads
wait

echo "Match User $sftpUserName" | sudo tee -a /etc/ssh/sshd_config
wait
echo "ForceCommand internal-sftp" | sudo tee -a /etc/ssh/sshd_config
wait
echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
wait
echo "ChrootDirectory /home/sftp" | sudo tee -a /etc/ssh/sshd_config
wait
echo "PermitTunnel no" | sudo tee -a /etc/ssh/sshd_config
wait
echo "AllowAgentForwarding no" | sudo tee -a /etc/ssh/sshd_config
wait
echo "AllowTcpForwarding no" | sudo tee -a /etc/ssh/sshd_config
wait
echo "X11Forwarding no" | sudo tee -a /etc/ssh/sshd_config
wait

sudo systemctl restart sshd
wait
sudo mount -t cifs $smbPath /home/sftp/uploads -o vers=3.0,username=$storageAccountName,password=$storageAccountKey,uid=$(id -u $sftpUserName),gid=$(id -g $sftpUserName),serverino


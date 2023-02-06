#!/usr/bin/env bash

set -e

# Set timezone (resolves hangs for non-interactive installs)
export DEBIAN_FRONTEND=noninteractive
ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime

# OS upgrade
apt-get update
apt-get upgrade -y -o Dpkg::Options::=--force-confdef

# Install basic packages
apt-get install -y apt-transport-https ca-certificates cifs-utils \
                   curl git gnupg2 jq lsb-release python3 python3-pip \
                   software-properties-common unzip vim zip

# Install docker cli
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install docker-ce-cli -y

# Install PowerShell 7
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install -y powershell

# Install TeamCity agent
unzip /tmp/teamcity_buildagent.zip -d /opt/buildagent
cp /opt/buildagent/conf/buildAgent.dist.properties /opt/buildagent/conf/buildAgent.properties
chmod +x /opt/buildagent/bin/*.sh

# Cleanup
apt autoclean
apt clean
apt autoremove --purge
rm -rf /tmp/*

#!/bin/bash

set -eux

defaultRegion='eu-central-1'
profile='./output/profile.ovpn'
profileBase=$( basename "${profile}" )
creds='./output/credentials.txt'

cd $( dirname "$0" )
cd ../..

# spinnig up an ovpn sever, configuring it, producting profile and credentials
terraform apply --auto-approve --var region=${defaultRegion}

# for the authentication error, edit the OVPN file and update the cipther to the AES-256-GCM (check logs first -> /var/log/openvpnas.log)
# https://forum.hackthebox.com/t/openvpn-issues-data-channel-cipher-negotiation-failed-no-shared-cipher/260307
cp "${profile}"{,backup}
sed 's/AES-256-CBC/AES-256-GCM/' -i "${profile}"

# retrieving password
username=$( cat "${creds}" | grep -oP '\[.*?\]' | grep 'username=' | sed -e 's/.$//' -e 's/^.*=//' )
password=$( cat "${creds}" | grep -oP '\[.*?\]' | grep 'password=' | sed -e 's/.$//' -e 's/^.*=//' )

# importing creds
nmcli connection import type openvpn file "${profile}"
nmcli connection modify "${profileBase%.*}" +vpn.data "username=${username}"
nmcli connection modify "${profileBase%.*}" vpn.secrets "password=${password}"
nmcli con up id "${profileBase%.*}"

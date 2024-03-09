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

# retrieving password
username=$( cat "${creds}" | grep -oP '\[.*?\]' | grep 'username=' | sed -e 's/.$//' -e 's/^.*=//' )
password=$( cat "${creds}" | grep -oP '\[.*?\]' | grep 'password=' | sed -e 's/.$//' -e 's/^.*=//' )

# importing creds
nmcli connection import type openvpn file "${profile}"
nmcli connection modify "${profileBase%.*}" +vpn.data "username=${username}"
nmcli connection modify "${profileBase%.*}" vpn.secrets "password=${password}"
nmcli con up id "${profileBase%.*}"

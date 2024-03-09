#!/bin/bash

set -eux

defaultRegion='eu-central-1'
profileBase=profile.ovpn

# delete the profile
nmcli connection delete "${profileBase%.*}" || :

cd $( dirname "$0" )
cd ../..

# spinnig up an ovpn sever, configuring it, producting profile and credentials
terraform destroy --auto-approve --var region=${defaultRegion}

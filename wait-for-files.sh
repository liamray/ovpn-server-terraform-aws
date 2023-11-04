#!/bin/bash

set -eu

counter=0

# we are expecting for 2 files in the [ovpn_remote_dir]
while [[ $( ls "${ovpn_remote_dir}" | wc -l ) -ne 2 ]] 2> /dev/null
do
  echo "Waiting for vpn server to produce necessary files in the [${ovpn_remote_dir}] remote directory..."
	let '++counter'
	sleep 5
	if [[ $counter -gt 60 ]]
	then
		echo "It seems like we have a problem creating a profile file. Try to re-run the terraform (destroy, apply)"
		exit 1
	fi
done

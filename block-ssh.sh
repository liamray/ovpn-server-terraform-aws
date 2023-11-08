#!/bin/bash

# installing aws cli
sudo apt update
sudo apt install unzip -y
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo sudo ./aws/install

aws ec2 revoke-security-group-ingress --group-name "${ovpn_sg_name}" --protocol tcp --port 22 --cidr 0.0.0.0/0

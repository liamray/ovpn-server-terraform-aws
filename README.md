# Personal OpvnVPN server

## TL;DR
This terraform script spins up a personal VPN server in the AWS cloud.

Run a

    terraform apply --auto-approve
command and you will get a 

    [profile.ovpn] and [credentials.txt]

files located in the

    [./output]

directory to connect to your personal OVPN server.

Edit a

    terraform.tfvars
    
file to change a region.




## The longer description
This terraform script spins up the ec2 instance in the AWS cloud based on ubuntu with t2.micro instance type. Then it installs an OpenVPN server there, makes setup, produces a vpn profile file and downloads it to your local machine to the **[./outout]** directory. For more security it disables OpenVPN Web UI and revokes ingress for SSH to the server in the security groups.

## AWS resources involved

* ec2 (t2.micro/t3.micro depending on region)
* key pair
* elastic ip
* IAM role and policy
* security group

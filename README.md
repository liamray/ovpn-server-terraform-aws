# Personal OpenVPN server

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

## The minimal IAM policy for terraform user

```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeImages",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DescribeInstanceCreditSpecifications",
				"ec2:DescribeVolumes",
				"ec2:DescribeInstanceAttribute",
				"ec2:DescribeTags",
				"ec2:ImportKeyPair",
				"ec2:CreateTags",
				"ec2:DescribeVpcAttribute",
				"ec2:CreateKeyPair",
				"ec2:DeleteKeyPair",
				"ec2:DescribeKeyPairs",
				"ec2:DescribeVpcs",
				"ec2:DescribeSubnets",
				"ec2:DescribeRouteTables",
				"ec2:DescribeInternetGateways",
				"ec2:CreateSecurityGroup",
				"ec2:DeleteSecurityGroup",
				"ec2:AuthorizeSecurityGroupIngress",
				"ec2:RevokeSecurityGroupIngress",
				"ec2:AuthorizeSecurityGroupEgress",
				"ec2:RevokeSecurityGroupEgress",
				"ec2:DescribeSecurityGroups",
				"ec2:DescribeInstanceTypeOfferings",
				"ec2:DescribeInstanceTypes",
				"ec2:RunInstances",
				"ec2:TerminateInstances",
				"ec2:DescribeInstances",
				"ec2:StopInstances",
				"ec2:StartInstances",
				"ec2:AllocateAddress",
				"ec2:ReleaseAddress",
				"ec2:DescribeAddresses",
				"ec2:AssociateAddress",
				"ec2:DisassociateAddress",
				"sts:GetCallerIdentity",
				"sts:GetSessionToken",
				"sts:AssumeRole",
				"iam:TagRole",
				"iam:ListInstanceProfilesForRole",
				"iam:ListEntitiesForPolicy",
				"iam:PassRole",
				"iam:ListPolicyVersions",
				"iam:TagInstanceProfile",
				"iam:GetPolicyVersion",
				"iam:GetPolicyVersion",
				"iam:GetPolicyVersion",
				"iam:ListAttachedRolePolicies",
				"iam:TagPolicy",
				"iam:ListRolePolicies",
				"iam:CreatePolicy",
				"iam:DeletePolicy",
				"iam:GetPolicy",
				"iam:ListPolicies",
				"iam:CreateRole",
				"iam:DeleteRole",
				"iam:GetRole",
				"iam:ListRoles",
				"iam:AttachRolePolicy",
				"iam:DetachRolePolicy",
				"iam:CreateInstanceProfile",
				"iam:DeleteInstanceProfile",
				"iam:GetInstanceProfile",
				"iam:ListInstanceProfiles",
				"iam:AddRoleToInstanceProfile",
				"iam:RemoveRoleFromInstanceProfile"
			],
			"Resource": "*"
		}
	]
}
```

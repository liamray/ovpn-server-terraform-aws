# searching for the ubuntu ami
data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "ssh_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_kp" {
  key_name   = "ovpn-key-pair"
  public_key = tls_private_key.ssh_key_pair.public_key_openssh
  tags = local.tags
}

data "aws_vpc" "default_vpc" {
  default = true
}

# openvpn ingress requirements: TCP (443, 943, 945), UDP (1194). we also temporary open a 22 port for different initializations
resource "aws_security_group" "ovpn_sgs" {
  description = "OVPN SGs"
  vpc_id      = data.aws_vpc.default_vpc.id
  tags = local.tags

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OVPN"
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OVPN"
    from_port   = 945
    to_port     = 945
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OVPN"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# some regions have only t3.micro instance type, but preffer to use a t2.micro as possible
data "aws_ec2_instance_type_offering" "instance_type" {
  filter {
    name   = "instance-type"
    values = ["t2.micro", "t3.micro"]
  }

  preferred_instance_types = ["t2.micro"]
}

# Create an IAM policy which allow to revoke security group rule (we want to remove an SSH access to the server)
resource "aws_iam_policy" "revoke_ingress_rule_policy" {
  name = "revoke-ingress-rule-policy-for-ovpn-server"
  tags = local.tags
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : "ec2:RevokeSecurityGroupIngress",
        "Resource" : "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current_account.account_id}:security-group/${aws_security_group.ovpn_sgs.id}"
      }
    ]
  })
}

# Create an IAM role
resource "aws_iam_role" "revoke_ingress_rule_role" {
  name = "revoke-ingress-rule-role-for-ovpn-server"
  tags = local.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "Service" : "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "revoke_ingress_attachment" {
  name       = "revoke-ingress-rule-attachment-for-OVPN-server"
  policy_arn = aws_iam_policy.revoke_ingress_rule_policy.arn
  roles      = [aws_iam_role.revoke_ingress_rule_role.name]
}

resource "aws_iam_instance_profile" "ovpn_instance_profile" {
  name = "ovpn-ec2-instance-profile"
  role = aws_iam_role.revoke_ingress_rule_role.name
  tags = local.tags
}

# the ec2 instance
resource "aws_instance" "ovpn_server" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = data.aws_ec2_instance_type_offering.instance_type.instance_type
  key_name               = aws_key_pair.my_kp.id
  vpc_security_group_ids = [aws_security_group.ovpn_sgs.id]

  iam_instance_profile = aws_iam_instance_profile.ovpn_instance_profile.name

  tags = local.tags
}

# the permanent ip address
resource "aws_eip" "ovpn_elastic_ip" {
  instance = aws_instance.ovpn_server.id
  tags = local.tags
}

data "aws_caller_identity" "current_account" {}

data "aws_iam_session_context" "current_user" {
  arn = data.aws_caller_identity.current_account.arn
}
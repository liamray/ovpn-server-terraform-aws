provider "aws" {
  region = "eu-central-1"
}

data "aws_ami" "ovpn_ami" {
  most_recent = true
  owners      = ["679593333241"] // openvpn market place
  name_regex  = "OpenVPN Access Server QA Image-.*"
}


resource "aws_key_pair" "my_kp" {
  key_name   = "my_kp"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_vpc" "default_vpc" {
  default = true
}

resource "aws_security_group" "ovpn_sgs" {
  description = "OVPN SGs"
  vpc_id      = data.aws_vpc.default_vpc.id

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

  tags = {
    Name = "OVPN sg"
  }
}

resource "aws_instance" "ovpn_server" {
  ami                    = data.aws_ami.ovpn_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_kp.id
  vpc_security_group_ids = [aws_security_group.ovpn_sgs.id]

  tags = {
    Name = "ovpn-server"
  }
}

resource "aws_eip" "ovpn_elastic_ip" {
  instance = aws_instance.ovpn_server.id
}


output "summary" {
  value = "First SSH to the server and setup it: ssh openvpnas@${aws_eip.ovpn_elastic_ip.public_ip} . And then enter to the portal and configure users: https://${aws_eip.ovpn_elastic_ip.public_ip}/admin"
}


/*
# you can use a command line to create a new user and produce an ovpn file
# and disable a web ui (you can also block a 443 and 943 ports in sgs as well to block a web ui)

cd /usr/local/openvpn_as/scripts
sudo su

username="<username>"
password="<password>"

# creating a new user
./sacli --user ${username} --key "type" --value "user_connect" UserPropPut
./sacli --user ${username} --new_pass ${password} SetLocalPassword

# generating an ovpn file
./sacli --prefer-tls-crypt-v2 --user ${username} GetUserlogin > /home/openvpnas/${username}.ovpn

# disabling web ui
./sacli --key "admin_ui.https.ip_address" --value lo ConfigPut
./sacli start


*/
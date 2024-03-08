resource "null_resource" "ovpn_setup" {
  depends_on = [aws_instance.ovpn_server]

  triggers = {
    always_run = "${timestamp()}"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key_pair.private_key_openssh

    host = aws_eip.ovpn_elastic_ip.public_ip
  }

  # setting up ovpn server
  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "export base_dir=${local.ovpn_remote_dir}",
      file("${path.module}/setup-ovpn-server.sh")
    ]
  }

  # making a local.ovpn_base_dir local dir
  provisioner "local-exec" {
    command = "mkdir -p '${local.ovpn_local_dir}'"
  }

  # creating a private key file
  provisioner "local-exec" {
    command = "echo '${tls_private_key.ssh_key_pair.private_key_openssh}' > '${local.ssh_private_key_file}' && chmod 400 '${local.ssh_private_key_file}'"
  }

  # copying files from the remote dir to the local dir
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.ssh_private_key_file} ubuntu@${aws_eip.ovpn_elastic_ip.public_ip}:${local.ovpn_remote_dir}/* ${local.ovpn_local_dir}"
  }

  # deleting a private key file locally (you can all always use instance connect in the AWS console instead)
  provisioner "local-exec" {
    command = "rm '${local.ssh_private_key_file}'"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",

      # deleting certs etc
      "sudo rm ${local.ovpn_remote_dir}/*",

      # revoking ssh access to ovpn server
      "aws ec2 revoke-security-group-ingress --group-name \"${aws_security_group.ovpn_sgs.name}\" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region=${var.region}"
    ]
  }
}

#!/bin/bash

set -eu

generate_random_password() {
    tr -dc 'A-Za-z0-9!#$%&*+=?@|~' </dev/urandom | head -c 20  ; echo
}

# installing the open-server
apt update -y
apt -y install ca-certificates wget net-tools gnupg
wget https://as-repository.openvpn.net/as-repo-public.asc -qO /etc/apt/trusted.gpg.d/as-repository.asc
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/as-repository.asc] http://as-repository.openvpn.net/as/debian jammy main">/etc/apt/sources.list.d/openvpn-as-repo.list
apt update -y
apt -y install openvpn-as

# generating random passwords for admin user (the admin username is openvpn)
admin_password=$( generate_random_password )

# backing up a python script
cp /usr/local/openvpn_as/bin/_ovpn-init{,.backup}

# modifying the script
sed -e '/^def request_password(/,/^    return passw, False/ s/^    .*//g' -e 's/^def request_password(.*/def request_password(user_name, pwd, input_message: str):\n    return \"'"${admin_password}"'\", False/g' -i '/usr/local/openvpn_as/bin/_ovpn-init'
sed '/activate_as(LICENSE)/d' -i '/usr/local/openvpn_as/bin/_ovpn-init'

# running open config utility with pre-defined options
ovpn-init --ec2 --force <<EOF
yes
yes
1
rsa
2048
rsa
2048
943
443
yes
yes
yes
yes

EOF

# restoring back the original script
cp /usr/local/openvpn_as/bin/_ovpn-init{.backup,}


user_name="ovpn"
user_password=$( generate_random_password )

base_dir="/home/ubuntu/ovpn-files"
mkdir -p "${base_dir}"

ovpn_file_name="profile.ovpn"
ovpn_file_path="${base_dir}/${ovpn_file_name}"

creds_file_name="credentials.txt"
creds_file_path="${base_dir}/${creds_file_name}"

# writing user creds to the file
echo  "To connecto to the open vpn use a [${ovpn_file_name}] file" > "${creds_file_path}"
echo  "You have to authenticate yourself with a [${user_name}] username and [${user_password}] password" >> "${creds_file_path}"
chown ubuntu:ubuntu "${creds_file_path}"

# creating user. the openvpn service still might be in progress, so trying to create a user multiple times
counter=0
while ! /usr/local/openvpn_as/scripts/sacli --user ${user_name} --key "type" --value "user_connect" UserPropPut
do
    sleep 3
    let '++counter'
    if [[ ${counter} -gt 10 ]]
    then
        echo "Failed to create a [${user_name}] user after multiple attempts"
        exit 1
    fi
done

# setting up a password
/usr/local/openvpn_as/scripts/sacli --user ${user_name} --new_pass "${user_password}" SetLocalPassword

# creating a profile (ovpn file)
/usr/local/openvpn_as/scripts/sacli --prefer-tls-crypt-v2 --user ${user_name} GetUserlogin > "${ovpn_file_path}"

# disabling web ui
/usr/local/openvpn_as/scripts/sacli --key "admin_ui.https.ip_address" --value lo ConfigPut || :
/usr/local/openvpn_as/scripts/sacli start || :

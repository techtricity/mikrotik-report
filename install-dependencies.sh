#!/bin/bash

OS_RELEASE=`awk -F= '/^NAME/{print $2}' /etc/os-release`
OS_RELEASE=$(sed -e 's/^"//' -e 's/"$//' <<< "$OS_RELEASE")

if [[ "$OS_RELEASE" == "Ubuntu" ]]; then

        sudo apt update

        sudo NEEDRESTART_MODE=a apt install net-tools -y
        sudo NEEDRESTART_MODE=a apt install mailutils -y
        sudo NEEDRESTART_MODE=a apt install geoip-database -y
        sudo NEEDRESTART_MODE=a apt install geoipupdate -y
        sudo NEEDRESTART_MODE=a apt install mmdb-bin -y
        sudo NEEDRESTART_MODE=a apt install whois -y
        sudo NEEDRESTART_MODE=a apt install uuid-dev -y

else
        echo "Unsupported OS: $OS_RELEASE"
fi

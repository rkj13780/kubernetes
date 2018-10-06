#!/bin/bash

# Take one argument from the commandline: VM name
if ! [ $# -eq 1 ]; then
    echo "Usage: $0 <node-name>"
    exit 1
fi

# Check if domain already exists
virsh dominfo $1 > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo -n "[WARNING] $1 already exists.  "
    read -p "Do you want to overwrite $1 [y/N]? " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
    else
        echo -e "\nNot overwriting $1. Exiting..."
        exit 1
    fi
fi

# Directory to store images
DIR=/root/Desktop/virt/images/

# Location of cloud image
IMAGE=$DIR/Centos-7-1808.qcow2

# Amount of RAM in MB
MEM=4120

# Number of virtual CPUs
CPUS=2

# Cloud init files
USER_DATA=user-data
META_DATA=meta-data
CI_ISO=$1-cidata.iso
DISK=$1.qcow2

# Bridge for VMs (default on Fedora is virbr0)
BRIDGE=virbr0

# Start clean
rm -rf $DIR/$1
mkdir -p $DIR/$1

pushd $DIR/$1 > /dev/null

    # Create log file
    touch $1.log

    echo "$(date -R) Destroying the $1 domain (if it exists)..."

    # Remove domain with the same name
    virsh destroy $1 >> $1.log 2>&1
    virsh undefine $1 >> $1.log 2>&1

    # cloud-init config: set hostname, remove cloud-init package,
    # and add ssh-key 
    cat > $USER_DATA << _EOF_
#cloud-config

# Hostname management
preserve_hostname: False
hostname: $1
fqdn: $1.k8s.com

# Remove cloud-init when finished with it
runcmd:
  - [ yum, -y, remove, cloud-init ]

# Configure where output will go
output: 
  all: ">> /var/log/cloud-init.log"

#added
debug: True
ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: False
runcmd:
  - sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
  - service sshd restart

# configure interaction with ssh server
ssh_svcname: ssh
ssh_deletekeys: True
ssh_genkeytypes: ['rsa', 'ecdsa']

# Install my public ssh key to the first user-defined user configured 
# in cloud.cfg in the template (which is centos for CentOS cloud images)
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhIOffJcOofA+9SF7MKi6qo1/BcLjfIXk4ERRS+xAwgJc0oAFfjH/o31Dyj1f6Pbsn0nKgVq5dVtjzB80FY6hXSvQq6weI65HPx7q7CBhKEuKvfSg8B5mh+Uj+XsrnBXMTN4ET8+Mn8W4V1KvB2e7baOjRu/F9EZeGySCfe1kLKF0OOZRwBMo3OE9W2zGW2f16cdS8rQaMxLJmlQYN3mmhjM/v3H9TIpzSZsZXZ7Bvy+aBzKD+r+eFk4s84tc6Tm2GdfKTHKRn0LnBvBe2Mu1psnnYzJQBz63bRPya1WK/zbdT+VXs1/GnxwexiXy5bO8O817oZIJkyRd2+Dd3JCcn root@devops

_EOF_

    echo "instance-id: $1; local-hostname: $1" > $META_DATA

    echo "$(date -R) Copying template image..."
    cp $IMAGE $DISK

    # Create CD-ROM ISO with cloud-init config
    echo "$(date -R) Generating ISO for cloud-init..."
    genisoimage -output $CI_ISO -volid cidata -joliet -r $USER_DATA $META_DATA &>> $1.log

    echo "$(date -R) Installing the domain and adjusting the configuration..."
    echo "[INFO] Installing with the following parameters:"
    echo "virt-install --import --name $1 --ram $MEM --vcpus $CPUS --disk
    $DISK,format=qcow2,bus=virtio --disk $CI_ISO,device=cdrom --network
    bridge=virbr0,model=virtio --os-type=linux --os-variant=rhel7 --noautoconsole"

    virt-install --import --name $1 --ram $MEM --vcpus $CPUS --disk \
    $DISK,format=qcow2,bus=virtio --disk $CI_ISO,device=cdrom --network \
    bridge=virbr0,model=virtio --os-type=linux --os-variant=rhel7 --noautoconsole

    MAC=$(virsh dumpxml $1 | awk -F\' '/mac address/ {print $2}')
    while true
    do
        IP=$(grep -B1 $MAC /var/lib/libvirt/dnsmasq/$BRIDGE.status | head \
             -n 1 | awk '{print $2}' | sed -e s/\"//g -e s/,//)
        if [ "$IP" = "" ]
        then
            sleep 1
        else
            break
        fi
    done

    # Eject cdrom
    echo "$(date -R) Cleaning up cloud-init..."
    virsh change-media $1 hda --eject --config >> $1.log

    # Remove the unnecessary cloud init files
    rm $USER_DATA $CI_ISO

    echo "$(date -R) DONE. SSH to $1 using $IP, with  username 'centos'."

popd > /dev/null


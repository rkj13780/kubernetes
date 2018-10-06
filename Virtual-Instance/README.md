# Kuberenets LAB Setup

Step 1 — KVM and QEMU installation

    yum install qemu-kvm qemu-img virt-manager libvirt libvirt-python libvirt-client virt-install virt-viewer bridge-utils
    systemctl start libvirtd
    systemctl enable libvirtd

Step 2 — libvirt packages install

    yum install -y libvirt-client virt-install genisoimage

Step 3 - Create images directory

    mkdir -p ~/virt/images

Step 4 — Download Image:

    cd ~/virt/images
    wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz

Step 5 — Extract the Image:

    xz --decompress CentOS-7-x86_64-GenericCloud.qcow2.xz

Step 6 —


Step 7 — Genereate RSA Key and copy to script.

    ssh-keygen

    vim ~/virt/Virtual-Instance/Virt-install-root.sh
    Note: Replace with above RSA Key

step 8 - Change RAM and CPU Configuration

    sed -i 's/MEM=4120/MEM=2048/g' ~/virt/Virtual-Instance/Virt-install-root.sh
    sed -i 's/CPUS=2/CPU=1/g' ~/virt/Virtual-Instance/Virt-install-root.sh

Step 9 — Create Instances

    sh ~/virt/Virtual-Instance/Virt-install-root.sh master
    sh ~/virt/Virtual-Instance/Virt-install-root.sh slave1
    sh ~/virt/Virtual-Instance/Virt-install-root.sh slave2
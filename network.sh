#!/bin/bash

# read in ' ' from command line
virt_ip=$1
virt_host=$2

# build the fqdn based off the short host name
virt_fqdn=${virt_host}.linux.bogus

# fill in your network defaults
virt_gateway=192.168.1.1
virt_netmask=255.255.225.0
virt_nameserver=192.168.1.101

# how the disk/ram/cpu is sized...http://blog.johngoulah.com/
virt_disk=10G
virt_ram=512
virt_cpus=1

# random mac address
virt_mac=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')

cp /var/lib/libvirt/images/debian-tmpl /var/lib/libvirt/images/${virt_host}-disk0

# optionally resize the disk
qemu-img resize /var/lib/libvirt/images/${virt_host}-disk0 ${virt_disk}
loopback=`losetup -f --show /var/lib/libvirt/images/${virt_host}-disk0`
fsck.ext3 -fy $loopback
resize2fs $loopback ${virt_disk}
losetup -d $loopback

mountbase=/tmp/${virt_host}
mkdir -p ${mountbase}
mount -o loop /var/lib/libvirt/images/${virt_host}-disk0 ${mountbase}

# replace our template vars
sed -i -e "s/ADDRESS-TMPL/$virt_ip/g" \
       -e "s/NETMASK-TMPL/$virt_netmask/g" \
       -e "s/GATEWAY-TMPL/$virt_gateway/g" \
       -e "s/HOSTNAME-TMPL/$virt_fqdn/g" \
       -e "s/NAMESERVER-TMPL/$virt_nameserver/g" \
  ${mountbase}/etc/network/interfaces \
  ${mountbase}/etc/resolv.conf \
  ${mountbase}/etc/hostname

# unmount and remove the tmp files
umount /tmp/${virt_host}
rm -rf /tmp/${virt_host}*

# run a file system check on the disk
fsck.ext3 -pv /var/lib/libvirt/images/${virt_host}-disk0

# specify the kernel and initrd (these we copied with scp earlier)
vmlinuz=/var/lib/libvirt/kernels/vmlinuz-2.6.32-5-amd64
initrd=/var/lib/libvirt/kernels/initrd.img-2.6.32-5-amd64

# install the new domain with our specified parameters for cpu/disk/memory/network
virt-install --name=$virt_host --ram=$virt_ram \
--disk=path=/var/lib/libvirt/images/${virt_host}-disk0,bus=virtio,cache=none \
--network=bridge=br0 --import --accelerate --vcpus=$virt_cpus --cpuset=auto --mac=${virt_mac} --noreboot --graphics=vnc \
--cpu=host --boot=kernel=$vmlinuz,initrd=$initrd,kernel_args="root=/dev/vda console=ttyS0 _device=eth0 \
_ip=${virt_ip} _hostname=${virt_fqdn} _gateway=${virt_gateway} _dns1=${virt_nameserver} _netmask=${virt_netmask}"

# start it up
virsh start $virt_host
#!/bin/bash -xv

sudo yum install systemd-timesyncd
sudo timedatectl set-ntp true 
sudo timedatectl timesync-status

sudo yum install libvirt-devel libvirt-daemon-kvm libvirt-client -y
sudo systemctl enable --now libvirtd
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-ipforward.conf
sudo sysctl -p /etc/sysctl.d/99-ipforward.conf

# https://github.com/openshift/installer/blob/master/docs/dev/libvirt/README.md#one-time-setup

sudo vim /etc/libvirt/libvirtd.conf

# listen_tls = 0
# listen_tcp = 1
# auth_tcp = "none"
# tcp_port = "16509"

sudo vim /lib/systemd/system/libvirtd.service

# [Unit]
# ...
# Wants=libvirtd-tcp.socket
# ...

sudo systemctl daemon-reload
sudo systemctl enable libvirtd-tcp.socket 

sudo yum -y install git
sudo yum -y install firewalld
sudo systemctl enable firewalld --now
sudo firewall-cmd --add-port=6443/tcp --permanent
sudo firewall-cmd --add-rich-rule "rule service name=libvirt reject" --permanent
sudo firewall-cmd --zone=libvirt --add-service=libvirt --permanent
sudo firewall-cmd --zone=dmz --change-interface=tt0 --permanent
sudo firewall-cmd --zone=dmz --add-service=libvirt --permanent
sudo firewall-cmd --zone=dmz --add-service=dns --permanent
sudo firewall-cmd --zone=dmz --add-service=dhcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all-zones
sudo systemctl enable systemd-resolved --now
sudo resolvectl dns tt0 192.168.126.1
sudo resolvectl domain tt0 crc.testing
sudo timedatectl set-timezone Asia/Tokyo
date
cat /etc/libvirt/qemu/networks/crc-lrvn9.xml
resolvectl domain

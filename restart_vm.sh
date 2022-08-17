#!/bin/bash

source functions.sh

echo
if [[ $(resolvectl | egrep -c 'Current DNS Server: 192.168.126.1|DNS Servers: 192.168.126.1|DNS Domain: crc.testing') -ne 3 ]]; then
    header "Setting up DNS and Domain:"
    sudo resolvectl dns tt0 192.168.126.1
    sudo resolvectl domain tt0 crc.testing
fi

VM=$(sudo virsh list --all | awk '/crc-/ { print $2 }')
if [[ $(sudo virsh domstate $VM | grep running) ]]; then
    header "Stopping VM:"
    sudo virsh destroy $VM
fi
header "Starting VM:"
sudo virsh start $VM

header "Waiting on bootup:"
waituntil "oc get clusterversion" "Cluster version is"
header "Waiting on settled:"
waituntil2 "oc get co --no-headers" "True *False *False" 30
oc whoami
oc get nodes

# watch -n1 oc get all -n openshift-machine-config-operator

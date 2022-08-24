#!/bin/bash

source ./functions.sh

trap ctrl_c INT

echo 
header Cloning bpftrace:
rm -rf ~/bpftrace; cd ~ || exit
eprint git clone https://github.com/iovisor/bpftrace
eprint cd ~/bpftrace/tools/
eprint ls -x \*.bt
recreate_ebpf
echo;header "Show capabilities tracing:"; read -t 10 -r
eprint kubectl-trace run "${MASTER}" -f capable.bt
waituntil "kubectl logs -f $(oc get pod -n ebpf --no-headers --sort-by '{.metadata.creationTimestamp}'| awk 'END{ print $1}')" "CAP"
echo;header "Show vfs tracing:"; read -t 10 -r
eprint kubectl-trace run "${MASTER}" -f vfsstat.bt
waituntil "kubectl logs -f $(oc get pod -n ebpf --no-headers --sort-by '{.metadata.creationTimestamp}'| awk 'END{ print $1}')" "vfs_"
echo;header "Show load avarage:"; read -t 10 -r
eprint kubectl-trace run "${MASTER}" -f loads.bt
waituntil "kubectl logs -f $(oc get pod -n ebpf --no-headers --sort-by '{.metadata.creationTimestamp}'| awk 'END{ print $1}')" "load averages"
header Clean up ebpf project:
waituntil "oc delete project ebpf" "NotFound"

#!/bin/bash


function waituntil {
	echo
	echo "$ ${1}"
	until ${1} 2>&1 | egrep -qi "${2}"; do
		echo -n .
		sleep 1
	done
	sleep 1
	echo
	eval ${1}
}

function eprint {
	echo
	echo "$ $*"
	eval "$*"
}

function recreate_ebpf {
	oc get project ebpf >/dev/null 2>&1 && 
	{ header "Deleting an existing ebpf project"; 
		waituntil "oc delete project ebpf" "NotFound"
	}
	header "Creating ebpf project"; 
	eprint oc new-project ebpf 2>/dev/null;
	header "Adding priviledge:"
	eprint oc adm policy add-scc-to-user privileged -z default -n ebpf;
	MASTER=$(kubectl get nodes | awk '/master/ { print $1 }')
}

function header {
	red=$'\e[1;31m'
	grn=$'\e[1;32m'
	yel=$'\e[1;33m'
	blu=$'\e[1;34m'
	mag=$'\e[1;35m'
	cyn=$'\e[1;36m'
	end=$'\e[0m'
	echo	
	printf "%s\n" "${red}$*${end}"
}

function ctrl_c { 
	pkill -f 'kubectl log'
	echo "Stopping kubectl log..."
	echo "CTRL-C again to stop script or resume in 2 seconds"
	sleep 2 || exit 1
}
 
trap ctrl_c INT
echo 
header Cloning bpftrace:
rm -rf ~/bpftrace; cd ~
eprint git clone https://github.com/iovisor/bpftrace
eprint cd ~/bpftrace/tools/
eprint ls -x \*.bt
recreate_ebpf
echo;header "Show capabilities tracing:"; read -t 10
eprint kubectl-trace run $MASTER -f capable.bt
waituntil "kubectl logs -f $(oc get pod -n ebpf --no-headers --sort-by '{.metadata.creationTimestamp}'| awk 'END{ print $1}')" "CAP"
echo;header "Show vfs tracing:"; read -t 10
eprint kubectl-trace run $MASTER -f vfsstat.bt
waituntil "kubectl logs -f $(oc get pod -n ebpf --no-headers --sort-by '{.metadata.creationTimestamp}'| awk 'END{ print $1}')" "vfs_"
echo;header "Show load avarage:"; read -t 10
eprint kubectl-trace run $MASTER -f loads.bt
waituntil "kubectl logs -f $(oc get pod -n ebpf --no-headers --sort-by '{.metadata.creationTimestamp}'| awk 'END{ print $1}')" "load averages"
header Clean up ebpf project:
waituntil "oc delete project ebpf" "NotFound"

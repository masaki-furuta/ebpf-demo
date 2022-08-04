#!/bin/bash


function waituntil {
	echo
	echo "$ ${1}"
	until ${1} 2>&1 | egrep -qi "${2}"; do
		echo -n .
		sleep 1
	done
	echo
	eval ${1}
}

function eprint {
	echo
	echo "$ $*"
	eval "$*"
}

function recreate_ebpf {
	waituntil "oc delete project ebpf" "NotFound"; oc new-project ebpf > /dev/null 2>&1
	eprint oc adm policy add-scc-to-user privileged -z default -n ebpf
	MASTER=$(kubectl get nodes | awk '/master/ { print $1 }')
}

function header {
	echo	
	echo "$*"
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
eprint git clone https://github.com/iovisor/bpftrace >/dev/null 2>&1 
eprint cd ~/bpftrace/tools/; git pull >/dev/null 2>&1
recreate_ebpf
echo;read -t 10 -p "Show capabilities tracing:"
eprint kubectl-trace run $MASTER -f capable.bt
waituntil "kubectl logs -f $(oc get pods -A | awk '/kubectl/ { print $2}')" "CAP"
recreate_ebpf
echo;read -t 10 -p "Show vfs tracing:"
eprint kubectl-trace run $MASTER -f vfsstat.bt
waituntil "kubectl logs -f $(oc get pods -A | awk '/kubectl/ { print $2}')" "vfs_"
recreate_ebpf
echo;read -t 10 -p "Show load avarage:"
eprint kubectl-trace run $MASTER -f loads.bt
waituntil "kubectl logs -f $(oc get pods -A | awk '/kubectl/ { print $2}')" "load averages"

#waituntil "oc delete pods $(oc get pods -A | awk '/kubectl/ { print $2}')" "NotFound"

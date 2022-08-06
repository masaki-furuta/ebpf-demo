#!/bin/bash -xv


test -f /etc/yum.repos.d/kubernetes.repo || \
sudo tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
rpm -q kubelet kubeadm kubectl || \
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
kubectl-trace || \
    { set -x; cd "$(mktemp -d)" && \
            OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
            ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
            KREW="krew-${OS}_${ARCH}" && \
            curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
            tar zxvf "${KREW}.tar.gz" && \
            ./"${KREW}" install krew ; export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" ; kubectl krew install trace; }

rpm -q bash-completion || sudo yum install bash-completion
export KUBECONFIG=~/snc/crc-tmp-install-data/auth/kubeconfig
export PATH=$PATH:~/snc/openshift-clients/linux/
grep KUBECONFIG ~/.bashrc || echo "export LC_ALL=en_US.UTF-8; export KUBECONFIG=~/snc/crc-tmp-install-data/auth/kubeconfig; export PATH=$PATH:~/snc/openshift-clients/linux/; export PATH=\"${KREW_ROOT:-$HOME/.krew}/bin:$PATH\" ; alias lv=less" >> ~/.bashrc
grep "oc completion bash" ~/.bashrc || echo 'source <(oc completion bash)' >> ~/.bashrc
grep "kubectl completion bash" ~/.bashrc || echo 'source <(kubectl completion bash)' >>~/.bashrc
watch -n 2 "oc get pods --all-namespaces | grep -v Running"

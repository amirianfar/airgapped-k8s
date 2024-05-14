#This script MUST install on ALL nodes. 
#!/bin/bash

#In Case of needing to change hostnames
#sudo hostnamectl set-hostname '<master/worker-k8s-node-1,2,3...>'

#Removing all previous versions and prereuisits. 
sudo rm -rf $HOME/.kube
sudo rm -rf /etc/kubernetes
sudo rm -rf /etc/cni/net.d
sudo rm -rf /etc/cni
sudo rm -rf /opt/cni/bin
sudo rm -rf /etc/containerd
sudo rm -rf /usr/local/bin
sudo rm /usr/lib/systemd/system/kubelet.service.d
sudo systemctl stop containerd
sudo systemctl stop kubelet


#Install general dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates socat iptables conntrack selinux-basics selinux-policy-default auditd  nfs-common podman iptables-persistent 

#Install containerd
sudo mkdir /etc/containerd
sudo cp configs/config.toml /etc/containerd/config.toml
sudo tar Cxzvf /usr/local bin/containerd-1.7.14-linux-amd64.tar.gz
sudo cp configs/containerd.service /etc/systemd/system/containerd.service 
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo chmod 666 /run/containerd/containerd.sock
#sudo systemctl status containerd


#Install runc
sudo install -m 755 bin/runc.amd64 /usr/local/sbin/runc


#Install CNI network plugins
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin bin/cni-plugins-linux-amd64-v1.1.1.tgz
sudo tar Cxzvf /usr/local/bin bin/crictl*.tar.gz

#Forward IPv4 and let iptables see bridged network traffic
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe -a overlay br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


# Ensure that SELinux is in permissive mode
sudo setenforce 0
sudo touch /etc/selinux/config
sudo bash -c 'cat <<EOF >  /etc/selinux/config
SELINUX=permissive
EOF'


#Ensure swap is disabled

# Turn off swap
sudo swapoff -a

# Disable swap Permanentely
sudo sed -i -e '/swap/d' /etc/fstab 

#Install kubeadm, kubelet & kubectl

DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"

sudo tar -C $DOWNLOAD_DIR -xzf bin/cni-plugins-linux-amd64-v1.1.1.tgz
sudo cp bin/{kubelet,kubeadm} $DOWNLOAD_DIR 
sudo chmod +x $DOWNLOAD_DIR/{kubeadm,kubelet}

sudo mkdir -p /usr/lib/systemd/system/kubelet.service.d
sudo cp configs/10-kubeadm.conf /usr/lib/systemd/system/kubelet.service.d

sudo cp configs/kubelet.service /usr/lib/systemd/system
sudo systemctl enable --now kubelet
#sudo systemctl status kubelet

sudo install -o root -g root -m 0755 bin/kubectl /usr/local/bin/kubectl

kubectl version

export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | tee -a ~/.bashrc
source ~/.bashrc

#Doing iptables final settings. 
sudo iptables -F
sudo iptables -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT


# reboot
# sudo kubeadm init --apiserver-advertise-address=<Master Node IP> --pod-network-cidr=10.244.0.0/16 --kubernetes-version=v1.30.0 --cri-socket=unix:///var/run/containerd/containerd.sock  --ignore-preflight-errors=Mem > ./kubeadm.init.log --v=5
# kubeadm token create --print-join-command

# In case of problem with pulling from local repository you can pulling images from a Docker local repository with these commands

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/registry.k8s.io/kube-apiserver:v1.30.0
# sudo ctr -n=k8s.io i tag <LocalDockerRepositoryIP>:5000/registry.k8s.io/kube-apiserver:v1.30.0 registry.k8s.io/kube-apiserver:v1.30.0 

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/registry.k8s.io/conformance:v1.30.0
# sudo ctr -n=k8s.io i tag <LocalDockerRepositoryIP>:5000/registry.k8s.io/conformance:v1.30.0 registry.k8s.io/conformance:v1.30.0

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/registry.k8s.io/kube-controller-manager:v1.30.0
# sudo ctr -n=k8s.io i tag <LocalDockerRepositoryIP>:5000/registry.k8s.io/kube-controller-manager:v1.30.0 registry.k8s.io/kube-controller-manager:v1.30.0

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/registry.k8s.io/kube-scheduler:v1.30.0
# sudo ctr -n=k8s.io i tag <LocalDockerRepositoryIP>:5000/registry.k8s.io/kube-scheduler:v1.30.0 registry.k8s.io/kube-scheduler:v1.30.0

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/registry.k8s.io/kube-proxy:v1.30.0
# sudo ctr -n=k8s.io i tag <LocalDockerRepositoryIP>:5000/registry.k8s.io/kube-proxy:v1.30.0 registry.k8s.io/kube-proxy:v1.30.0 

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/registry.k8s.io/etcd:3.5.12-0
# sudo ctr -n=k8s.io i tag <LocalDockerRepositoryIP>:5000/registry.k8s.io/etcd:3.5.12-0 registry.k8s.io/etcd:3.5.12-0

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/registry.k8s.io/coredns/coredns:v1.11.1
# sudo ctr -n=k8s.io i tag <LocalDockerRepositoryIP>:5000/registry.k8s.io/coredns/coredns:v1.11.1 registry.k8s.io/coredns/coredns:v1.11.1

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/registry.k8s.io/pause:3.9
# sudo ctr -n=k8s.io i tag <LocalDockerRepositoryIP>:5000/registry.k8s.io/pause:3.9 registry.k8s.io/pause:3.9

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/csi:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/csi:v3.27.3 docker.io/calico/csi:v3.27.3

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/node-driver-registrar:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/node-driver-registrar:v3.27.3 docker.io/calico/node-driver-registrar:v3.27.3

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/pod2daemon-flexvol:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/pod2daemon-flexvol:v3.27.3 docker.io/calico/pod2daemon-flexvol:v3.27.3

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/cni:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/cni:v3.27.3 docker.io/calico/cni:v3.27.3

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/apiserver:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/apiserver:v3.27.3 docker.io/calico/apiserver:v3.27.3

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/typha:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/typha:v3.27.3 docker.io/calico/typha:v3.27.3

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/quay.io/tigera/operator:v1.32.7
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/quay.io/tigera/operator:v1.32.7 quay.io/tigera/operator:v1.32.7

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/ctl:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/ctl:v3.27.3 docker.io/calico/ctl:v3.27.3

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/kube-controllers:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/kube-controllers:v3.27.3 docker.io/calico/kube-controllers:v3.27.3

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/dikastes:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/dikastes:v3.27.3 docker.io/calico/dikastes:v3.27.3

# sudo ctr -n=k8s.io i pull --plain-http=true <LocalDockerRepositoryIP>:5000/calico/node:v3.27.3
# sudo ctr -n=k8s.io i tag  <LocalDockerRepositoryIP>:5000/calico/node:v3.27.3 docker.io/calico/node:v3.27.3









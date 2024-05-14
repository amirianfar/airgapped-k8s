#This script MUST RUN JUST on MASTER nodes. 
# During the procosses a file called "cni.kubeconfig" will build. Copy this cni.kubeconfig file to every node in the cluster.
#!/bin/bash


if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "You must run this script as a root user!"
    exit
fi

cp bin/calico /opt/cni/bin
chmod 755 /opt/cni/bin/calico

cp bin/calico-ipam /opt/cni/bin
chmod 755 /opt/cni/bin/calico-ipam

mkdir -p /etc/cni/net.d/
cp cni.kubeconfig /etc/cni/net.d/calico-kubeconfig
chmod 600 /etc/cni/net.d/calico-kubeconfig

kubectl create -f configs/tigera-operator.yaml
kubectl create -f configs/custom-resources.yaml


#Verify Calico installation in your cluster.
watch kubectl get pods -n calico-system









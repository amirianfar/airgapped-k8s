# kubernetes_1.30.0

This script automaticalliy run an Offline (Air-Gapped) Kubernetes cluster with Calico CNI. Before running the script please follow the steps: <br>
1- Run a Docker private docker registry in a system with internet connection. More information on: https://www.docker.com/blog/how-to-use-your-own-registry-2/ <br>
2- Pull these sort of images for both Kuberenetes and Calico from official repositories. <br>
    
    - registry.k8s.io/kube-apiserver                           v1.30.0               
    - registry.k8s.io/conformance                              v1.30.0               
    - registry.k8s.io/kube-scheduler                           v1.30.0               
    - registry.k8s.io/kube-controller-manager                  v1.30.0               
    - registry.k8s.io/kube-proxy                               v1.30.0               
    - bitnami/kube-state-metrics                               2.12.0-debian-12-r2   
    - quay.io/tigera/operator                                  v1.32.7               
    - docker.io/calico/typha                                   v3.27.3               
    - docker.io/calico/dikastes                                v3.27.3               
    - docker.io/calico/ctl                                     v3.27.3               
    - docker.io/calico/apiserver                               v3.27.3               
    - docker.io/calico/node-driver-registrar                   v3.27.3               
    - docker.io/calico/csi                                     v3.27.3               
    - docker.io/calico/pod2daemon-flexvol                      v3.27.3               
    - quay.io/derailed/k9s                                     latest                
    - registry.k8s.io/pause                                    3.9                   
    - quay.io/calico/node                                      latest              
    - quay.io/calico/cni                                       latest               
    - quay.io/calico/kube-controllers                          latest                
    - registry.k8s.io/etcd                                     3.5.12-0              
    - registry.k8s.io/coredns/coredns                          v1.11.1              

3- Push above images to your own docker private registry. <br>
4- Check all scripts and replace your own docker private IP with <LocalDockerRepositoryIP> <br>
5- You also need to do above step in configs/config.toml and configs/custom-resources.yaml <br>
6- Enjoy! <br>

Notice: If you faced any problem regarding pulling images from your own repository you can simply uncommnet pulling commands in related scripts. 


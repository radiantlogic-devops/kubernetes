# Setting up K8s

The following steps are curated by following this kubernetes setup [documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) 

## Prerequisites

- **Have at least 3 Linux VM’s with 4 CPU and 8GB RAM recommended. For this setup, I will be using Ubuntu 20.04 LTS on all the nodes**
- **One node will be acting as a master(controlplane) and the other two will be acting as worker nodes(node01,node02)**
- **Add host entries of controlplane on all the nodes(node01, node02) at /etc/hosts. This step is optional if you will address the controlplane with a static IP address.**
    - How to configure static IP?
        
        Please remember this following step will only ask the node to negotiate configured IP address, In few cases DHCP gateway may not allocate the requested IP, Best way set static IP will be at gateway.
        
        [https://linuxhint.com/setup_static_ip_address_ubuntu/](https://linuxhint.com/setup_static_ip_address_ubuntu/)
        
- **Verify each VM has a different hostname and are able to ping each other**
- **Port 6443 need to be exposed on the main server for clients(worker) nodes to connect**
- **Turn off swap on all the nodes**
    - How to turn off swap?
        
        comment a line that contains swap in this file /etc/fstab and reboot
        
        ```bash
        sudo vi /etc/fstab
        # /etc/fstab: static file system information.
        #
        # Use 'blkid' to print the universally unique identifier for a
        # device; this may be used with UUID= as a more robust way to name devices
        # that works even if disks are added and removed. See fstab(5).
        #
        # <file system> <mount point>   <type>  <options>       <dump>  <pass>
        # / was on /dev/ubuntu-vg/ubuntu-lv during curtin installation
        /dev/disk/by-id/dm-uuid-LVM-fvg48xLK8FM79tNe9CzTZH3Kvo8x3VxtEKIBCKEdJ4BKeeXWJq0WHfLgsN8fvUfB / ext4 defaults 0 0
        # /boot was on /dev/sda2 during curtin installation
        /dev/disk/by-uuid/36dd85d9-b3a6-4d9a-9f62-c291277f8998 /boot ext4 defaults 0 0
        #/swap.img       none    swap    sw      0       0
        ```
        
- **Configure iptables to see the bridged traffic**
    - [Letting iptables see bridged traffic](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic)
        
        Make sure that the `br_netfilter` module is loaded. This can be done by running `lsmod | grep br_netfilter`. To load it explicitly call `sudo modprobe br_netfilter`.
        
        As a requirement for your Linux Node's iptables to correctly see bridged traffic, you should ensure `net.bridge.bridge-nf-call-iptables` is set to 1 in your `sysctl` config, e.g.
        
        ```bash
        cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
        br_netfilter
        EOF
        
        cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
        net.bridge.bridge-nf-call-ip6tables = 1
        net.bridge.bridge-nf-call-iptables = 1
        EOF
        sudo sysctl --system
        ```
        

## **Objectives**

- Installing container runtime interface (Installing docker) on all nodes
- Installing kubeadm, kubelet and kubectl on all nodes
- Install a single control-plane Kubernetes cluster
- Install a Pod network(CNI) on the cluster so that your Pods can talk to each other
- Adding nodes to the cluster
- Installing kubernetes dashboard
- Installing local-path-provisioner for persistent volumes
- Installing Istio for ingress using Helm

### Installing container runtime interface (Installing docker) on all nodes

You can follow docker installation steps from the official website [here](https://docs.docker.com/engine/install/), I have placed steps for ubuntu distro below

- Uninstall old versions

```bash
sudo apt-get remove docker docker-engine [docker.io](http://docker.io/) containerd runc
```

- Installing docker using repo

```bash
sudo apt-get update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

- Add Docker official GPG key

```bash
curl -fsSL [https://download.docker.com/linux/ubuntu/gpg](https://download.docker.com/linux/ubuntu/gpg) | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

- Set stable release in apt repo list

```bash
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

- Install docker engine

```bash
 sudo apt-get update
 sudo apt-get install docker-ce docker-ce-cli containerd.io
```

- Check installation is success

```bash
sudo docker run hello-world
```

- Add yourself to docker group to run docker without sudo

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
```

> Logout of the session and login back to run docker without sudo
> 
- Configure the Docker daemon, in particular to use systemd for the management of the container’s cgroups.

```bash
sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
```

- Restart docker

```bash
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Installing kubeadm, kubelet and kubectl on all nodes

> `kubeadm`: the command to bootstrap the cluster.
> 

> `kubelet`: the component that runs on all of the machines in your cluster and does things like starting pods and containers.
> 

> `kubectl`: the command line util to talk to your cluster.
> 
- Update the apt package index and install packages needed to use the Kubernetes apt repository:

```bash
sudo apt-get update
```

```bash
sudo apt-get install -y apt-transport-https ca-certificates curl
```

 Download the Google Cloud public signing key:

```bash
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg [https://packages.cloud.google.com/apt/doc/apt-key.gpg](https://packages.cloud.google.com/apt/doc/apt-key.gpg)
```

Add the Kubernetes apt repository:

```bash
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] [https://apt.kubernetes.io/](https://apt.kubernetes.io/) kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
```

```bash
sudo apt-mark hold kubelet kubeadm kubectl
```

### Install a single control-plane Kubernetes cluster

- Initializing your control-plane node

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

> Above cidr will support setting up flannel CNI, If you are planning to use any other CNI in this [list](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model), Go through the setup documentation before initializing the controlplane
> 
- Once the intialization is successful you will see this following output

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a Pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  /docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

- Run the suggested commands to import kubeconfig and run kubectl as regular user

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

- Test kubectl

```bash
kubectl get nodes
```

```bash
kubectl cluster-info
```

> By default, your cluster will not schedule Pods on the control-plane node for security reasons. If you want to be able to schedule Pods on the control-plane node, for example for a single-machine Kubernetes cluster for development, run:
> 
> 
> ```bash
> kubectl taint nodes --all [node-role.kubernetes.io/master-](http://node-role.kubernetes.io/master-)
> ```
> 
> With output looking something like:
> 
> ```
> node/controlplane01 untainted
> ```
> 

### Install a Pod network(CNI) on the cluster so that your Pods can talk to each other

- Installing [flannel-io](https://github.com/flannel-io/flannel) CNI (Supported on Kubernetes 1.17 and higher)

```bash
kubectl apply -f [https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml](https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml)
```

- Verify all pods are up and running

```bash
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                     READY   STATUS    RESTARTS   AGE
kube-system   coredns-78fcd69978-k4f72                 1/1     Running   0          3m43s
kube-system   coredns-78fcd69978-xtn98                 1/1     Running   0          3m43s
kube-system   etcd-controlplane01                      1/1     Running   0          3m56s
kube-system   kube-apiserver-controlplane01            1/1     Running   0          3m56s
kube-system   kube-controller-manager-controlplane01   1/1     Running   0          3m57s
kube-system   kube-flannel-ds-f84lk                    1/1     Running   0          43s
kube-system   kube-proxy-jc7hn                         1/1     Running   0          3m42s
kube-system   kube-scheduler-controlplane01            1/1     Running   0          3m56s
```

### Adding nodes to the cluster

You should already have join command during controlplane initialization, Switch to root user or use sudo and run the command

```bash
kubeadm join --token <token> <control-plane-host>:<control-plane-port> --discovery-token-ca-cert-hash sha256:<hash>
```

If you dont have the command run following command to fetch your `token` on controlplane

```bash
kubeadm token list
```

Now get `—discovery-token-ca-cert-hash` by running the following command

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | **\**
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

Once all the nodes are added, perform a check 

```bash
kubectl get nodes
```

### Installing kubernetes dashboard

Official documentation for installing kubernetes dashboard is [here](https://github.com/kubernetes/dashboard)

```bash
kubectl apply -f [https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml](https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml)
```

You can create a simple admin user to access the dashboard with token with following `YAML` files

```bash
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
```

```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
```

Now apply these configurations using kubectl

```bash
kubectl apply -f admin-user.yaml
kubectl apply -f admin-user-role.yaml
```

Get the login token

```bash
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
```

> You can also run all the above mentioned steps, All together with below command for a quick install of dashboard and setup sample admin user
> 
> 
> ```bash
> kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml && \
>  kubectl apply -f https://raw.githubusercontent.com/vamzi/HelperScripts/main/kubernetes/dashboard/admin-user.yaml && \
>  kubectl apply -f https://raw.githubusercontent.com/vamzi/HelperScripts/main/kubernetes/dashboard/admin-user-role.yaml && \
>  kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
> ```
> 

Access the dashboard (Run this command from you local machine)

```bash
kubectl proxy —port=8001
```

### Installing local-path-provisioner for persistent volumes

> [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) provides a way for the Kubernetes users to utilize the local storage in each node. Based on the user configuration, the Local Path Provisioner will create hostPath based persistent volume on the node automatically. It utilizes the features introduced by Kubernetes Local Persistent Volume feature, but make it a simpler solution than the built-in local volume feature in Kubernetes.
> 
- Create `/opt/local-path-provisioner` on all nodes

```bash
sudo mkdir -p /opt/local-path-provisioner
```

- Install the storageclass

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

- Verify installation

```
$ kubectl -n local-path-storage get pod
NAME                                     READY     STATUS    RESTARTS   AGE
local-path-provisioner-d744ccf98-xfcbk   1/1       Running   0          7m
```

- Check and follow the provisioner log using

```bash
kubectl -n local-path-storage logs -f -l app=local-path-provisioner
```

- List storageclasses

```bash
kubectl get storageclasses
```

```
$ kubectl get storageclasses
NAME         PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  40m
```

- Set local-path as default storageclass

```bash
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Installing Istio for ingress using Helm

These steps listed below are using helm, If you are looking to use other option you can checkout [istio installation guides](https://istio.io/latest/docs/setup/install/)

- Create a namespace istio-system for Istio components

```bash
kubectl create namespace istio-system
```

- Install the Istio base chart which contains cluster-wide resources used by the Istio control plane

```bash
helm install istio-base manifests/charts/base -n istio-system
```

- Install the Istio discovery chart which deploys the istiod service

```bash
helm install istiod manifests/charts/istio-control/istio-discovery \
    -n istio-system
```

- Install the Istio ingress gateway chart which contains the ingress gateway components

```bash
helm install istio-ingress manifests/charts/gateways/istio-ingress \
    -n istio-system
```

- Install the Istio egress gateway chart which contains the egress gateway components

```bash
helm install istio-egress manifests/charts/gateways/istio-egress \
    -n istio-system
```
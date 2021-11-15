# kubernetes
Kubernetes manifest files for FID deployment 

The following kubernetes manifest files in this monitoring stack are imitating exact setup from [docker-compose](https://github.com/radiantlogic-devops/docker-compose) repo that consists of [monitoring-stack](https://github.com/radiantlogic-devops/docker-compose/tree/master/05-monitoring-stack)

## Prerequisites
- `kubectl`  [Download Instructions]: <https://kubernetes.io/docs/tasks/tools/>
- Access to kubernetes cluster `kubeconfig` file
- In this setup we will use `monitoring` & `fid-demo` namespaces. Make sure they are not used. Run the following commands to use.
> If you already have a monitoring namespace setup you can skip setting up monitoring namespace. Make sure `pushgateway.monitoring` has been setup in yours.
```
kubectl create namespace monitoring
kubectl create namespace fid-demo
```

## Installation
- Apply monitoring kubernetes manifest files in `monitoring` namespace
```
kubectl apply -f monitoring -n monitoring
```

- Apply `fid`, `zookeeper` & load generating stacks in `fid-demo` namespace
```
kubectl apply -f fid-demo -n fid-demo
```





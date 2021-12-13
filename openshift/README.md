# Openshift Platform

### At its core, OpenShift is a cloud-based Kubernetes container platform that's considered both containerization software and a platform-as-a-service (PaaS).

## Pre-Requisites

- Root Images cannot be used in Openshift . Therefore, we must create/use a non-root image.

> By default, OpenShift Container Platform runs containers using an arbitrarily assigned user ID. This provides additional security against processes escaping the container due to a container engine vulnerability and thereby achieving escalated permissions on the host node.
> 

(sample zk and fid for non-root Dockerfile mentioned in github)

## Configuration

### 1. Setup of Cluster

```bash
$crc setup
$crc start 
#Using cached Openshift Client Binary (for oc)
$ eval $(crc oc-env)

```

### 2. Create a new project

```bash
$oc new-project <project_name>

```

## Deployment

### 1. Apply Statefulsets

```bash
$oc create -f myobject.yaml -n <myproject>
```

### Using UI

```bash
$oc login -u kubeadmin -p <password>
$crc console

#if you have forgot your password,use the below command
$crc concole --credentials

#Apply zk.yaml first then apply configmaps.yaml and fid.yaml
#NOTE:- zk_connection_string=<service_name>.<namesapce>:2181
```

- Import YAML from LocalMachine (Developer Section > Add > {Import YAML from LocalMachine}



## Expose Services

### 1. Create port forwarding session to a port on a pod

```bash
$oc port-forward <pod_name> <host_port>:<pod_port>
```

## Troubleshooting Commands

```bash
$oc get pods
$oc status
# Review events within the namespace for diagnostic information relating to pod failures:
$oc get events
# Query logs for a specific pod
$oc logs <pod_name>
```

## Helm Deployment

### 1.**Setup**

Download the Helm binary and add it to your path:

```bash
$curl -L https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest/helm-linux-amd64 -o /usr/local/bin/helm
```

Make the Binary file executable

```bash
$chmod +x /usr/local/bin/helm
```

For Windows & Mac :- [https://docs.openshift.com/container-platform/4.3/cli_reference/helm_cli/getting-started-with-helm-on-openshift-container-platform.html](https://docs.openshift.com/container-platform/4.3/cli_reference/helm_cli/getting-started-with-helm-on-openshift-container-platform.html)

### 2. Installing Helm Charts

For zookeeper

```bash
$helm install --namespace=<name space> <release name> radiantone/zookeeper \
--set image.repository=<Openshift_zk_image>
--set.image.tag="latest"
```

For FID

```bash
$helm install --namespace=<name space> <release name> radiantone/fid \
--set image.repository=<Openshift_FID_Image> \
--set image.tag="latest" \
--set serviceAccount.annotations.name=restricted \
--set zk.connectionString="zk1-zookeeper.rli:2181" \ 
--set zk.ruok="http://zk1-zookeeper.rli:8080/commands/ruok"
```

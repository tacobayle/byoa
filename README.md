# byoa (Bring your Own AKO Demo)

## Goal of this repo

This repo spin up a full Avi environment in vCenter in conjunction with 2 \* k8s clusters in order to demonstrate AKO:

- cluster#1 uses Calico with ClusterIP
- cluster#2 uses Antrea with LocalNodePort
- Every machine is using DCHP so no static IPs is used

## Prerequisites:

A Jumpbox which has terraform installed

- Terraform:

```shell
ubuntu@ubuntuguest:~/bash_byoa$ terraform -v
Terraform v1.0.6
on linux_amd64
```

https://learn.hashicorp.com/tutorials/terraform/install-cli

- Inside the target vCenter:
  - Have a VM template ready for Avi Controller called `controller-21.1.1-template`
  - Have a VM template ready for Ubuntu focal called `ubuntu-focal-20.04-cloudimg-template`
  - Have a VM template ready for Ubuntu bionic called `ubuntu-bionic-18.04-cloudimg-template`
  - DHCP available for the following networks:
    - management network defined in vcenter.management_network.name
    - k8s network defined in vcenter.k8s_network.name

## VM Templates

This lab is using the template under the Nicolas folder templates and it is using ubuntu-bionic-18.04-cloudimg-template

## clone this repo:

git clone https://github.com/tacobayle/byoa

## Variables:

- Define the following environment variables:
  - `vsphere_user`
  - `vsphere_password`
  - `vsphere_server`
  - `avi_password`
  - `avi_username`
  - `avi_vsphere_user`
  - `avi_vsphere_password`
  - `avi_vsphere_server # use IP and not FQDN`
  - `docker_registry_username # this will avoid download issue when downloading docker images`
  - `docker_registry_password # this will avoid download issue when downloading docker images`
  - `docker_registry_email # this will avoid download issue when downloading docker images`

which can be defined as the example below which uses a file called env.txt

IMPORTANT: You must verify that the variable are set. Run echo $TF_VAR_vsphere_user and make sure you get your user.

To load the variables use the following command:

```
export $(xargs <env.txt)
```

ENV file:

```
export TF_VAR_vsphere_user=XXX
export TF_VAR_vsphere_password=XXX
export TF_VAR_vsphere_server=XXX

export TF_VAR_avi_password=XXX
export TF_VAR_avi_username=XXX

export TF_VAR_avi_vsphere_user=XXX
export TF_VAR_avi_vsphere_password=XXX
export TF_VAR_avi_vsphere_server=XXX


export TF_VAR_docker_registry_password=XXX
export TF_VAR_docker_registry_email=XXX
export TF_VAR_docker_registry_username=XXX
```

- Define the following vCenter variables inside vcenter.json

```
{
  "vcenter": {
    "dc": "wdc-06-vc12",
    "cluster": "wdc-06-vc12c01",
    "datastore": "wdc-06-vc12c01-vsan",
    "resource_pool": "wdc-06-vc12c01/Resources",
    "folder": "Nic_K8S",
    "management_network": {
      "name": "vxw-dvs-34-virtualwire-3-sid-6120002-wdc-06-vc12-avi-mgmt"
    },
    "vip_network": {
      "name": "vxw-dvs-34-virtualwire-120-sid-6120119-wdc-06-vc12-avi-dev116",
      "cidr": "10.1.1.0/24"
    },
    "k8s_network": {
      "name": "vxw-dvs-34-virtualwire-116-sid-6120115-wdc-06-vc12-avi-dev112"
    }
  }
}
```

- For the SE doing the demo, most of the other variables used can be kept as currently set. No need to change anything.

## Use terraform apply to:

- Create a new folder within vCenter
- Create a jump host within the vCenter folder attached to management network leveraging DHCP
- Create a client VM within the vCenter folder attached to management network leveraging DHCP and to the vip network using a static IP (defined in client.vip_IP) with Avi DNS configured as DNS server
- Create/Configure 2 \* k8s clusters:
  - master and worker nodes are attached to management network and k8s network leveraging DHCP
  - 1 master node per cluster
  - 2 workers nodes per cluster
  - k8S version is defined per cluster in variables.tf (vmw.kubernetes.[].version)
  - Docker version is defined per cluster in variables.tf (vmw.kubernetes.[].docker.version)
  - AKO version is defined per cluster in variables.tf (vmw.kubernetes.[].ako.version)
  - CNI name is defined (vmw.kubernetes.[].cni.name)
  - CNI yaml manifest url is defined (vmw.kubernetes.[].cni.url)
- Spin up 1 Avi Controller VM within the vCenter folder attached to management network leveraging DHCP
- Configure Avi Controller:
  - Bootstrap Avi Controller (Password, NTP, DNS)
  - VMW cloud
  - Service Engine Groups (Default SEG is used for VMware Cloud and by cluster#2), a dedicated SEG is configured for cluster#1
  - DNS VS is used in order to demonstrate FQDN registration reachable outside k8s cluster

## Run terraform:

- create:

```
terraform init
terraform apply -auto-approve -var-file=vcenter.json
```

- destroy:

```
Use the command provided by terraform output
```

The terraform output should look similar to the following:

```
ssh -o StrictHostKeyChecking=no -i ~/.ssh/ssh_private_key-remo_ako.pem -t ubuntu@100.206.114.98 'cd aviAbsent ; ansible-playbook local.yml --extra-vars @~/.avicreds.json' ; sleep 5 ; terraform destroy -auto-approve -var-file=vcenter.json
```

## Demonstrate AKO

- Warnings:
  - the SE takes few minutes to come up
  - an alias has been created to use "k" instead of "kubectl" command
  - all the VS are reachable by connecting to the client vm using the FQDN of the VS
  - be patient when you try to test the app from the client VM (cluster 1 will need new SEs) and the DNS registration takes a bit of time
- connect to one of the master node using terraform output commands like : `ssh -i ... ubuntu@ip_of_the_master_node`
- AKO installation on each master node: command generated by the output of the Terraform plan to be applied: `helm install ...`
- `k get pods -A` will show you the ako pod
- K8s deployment: `k apply -f deployment.yml`
- `k get deployment` will show you the deployment(s)
- K8s service type ClusterIP: `k apply -f service_clusterIP.yml`
- `k get svc` will show you the service(s)
- Create a K8s service (type LB): `k apply -f service_loadBalancer.yml` - this triggers a new VS in the Avi controller
- `k get svc` will show you the service(s)
- Scale your deployment: `k scale deployment web-front1 --replicas=6` - this scales the pool in the Avi Controller
- `k get deployment` will show you the pods for each deployment
- Create an ingress (unsecured): `k apply -f ingress.yml` - this triggers a new VS (parent VS) in the Avi controller
- `k get ingress` will show you the ingress
- Create a secured ingress (based on a TLS cert already configured in a K8s secret): `k apply -f secure_ingress.yml` - this triggers a new VS (child VS) in the Avi controller
- `k get ingress` will show you the ingress
- Apply a WAF policy to your secured ingress: `k apply -f avi_crd_hostrule_waf.yml` - this triggers a WAF policy to be attached to the child VS in the Avi controller
- Upgrade your unsecured ingress to a secure ingress (based on a TLS cert already configured in the Avi Controller): `k apply -f avi_crd_hostrule_tls_cert.yml` - this triggers a new VS (child VS) in the Avi controller

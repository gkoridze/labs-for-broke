hosting example files for a [blog post](https://georgedeblog.com/blog/labs-for-broke/)

Covering blockhead part of the blog.


# Instructions

sensetive data is provided with a local json file aws_creds.json. 
```
{
  "region" : "eu-central-1",
  "ssh_key_pair" : "",
  "access_key" : "",
  "secret_key" : "",
  "wg_private" : "",
  "wg_public" : "",
  "wg_peers" : { 
                 "1" : ""
               } 
}
```

|Key | Description | Type | example |
|-|-|-|-|
| region | AWS Region | String | eu-central-1 |
| access_key | AWS Access Key | String | |
| ssh_key_pair | Name of SSH Key pair | String | |
| secret_key | AWS Secret Key | String | | 
| wg_private | Private Key of WireGuard Server | String | | 
| wg_public | Public Key of WireGuard Server | String | | 
| wg_peers | Object containg list of WireGuard Peers | Object |
| wg_peers{} | consists of id equels Public Key(Peer), id is used to generate allowed ip: 1 = 10.70.88.101/24 | | |
 
**PreRequsites**

local binaries:
* terraform
* butane
* jq
* kubectl

ssh conf ~/.ssh/config
```
Host control-0*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host worker-0*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host 10.10.16.*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
Host kubelius-*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

Hosts File

```
10.10.16.10 api.kubelius
10.10.16.11 control-01
10.10.16.12 control-02
10.10.16.13 control-03
```

---

1. create aws_creds.json

2. download terraform deps
```
terraform init
```

3. apply
```
terraform apply
```

3. retrive vpn config for client
```
cat terraform.tfstate | jq .outputs.vpn_client.value -r | base64 -d 
```
4. Retrive Kubeconfig
```
cat terraform.tfstate | jq .outputs.superadmin64.value -r | base64 -d > /tmp/kubelius.conf
export KUBECONFIG=/tmp/kubelius.conf
kubectl get nodes
```

---

**Destroy**

```
terraform destroy
```

**Recreate**
```
terraform apply
#Update VPN Endpoint in client
cat terraform.tfstate | jq .outputs.superadmin64.value -r | base64 -d > /tmp/kubelius.conf
export KUBECONFIG=/tmp/kubelius.conf
kubectl get nodes
```


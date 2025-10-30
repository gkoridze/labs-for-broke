hosting example files for a [blog post](https://georgedeblog.com/blog/labs-for-broke/)

Covering kubeadm part of the blog.


# Instructions

sensetive data is provided via local json file called aws_creds.json. 
```
{
  "region" : "eu-central-1",
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

4. init first node
```
ssh core@10.10.16.11
sudo su - 
kubeadm init --config  /etc/kube-cluster.config  --ignore-preflight-errors=NumCPU,Mem
```

5. Distribute Certificates to other nodes
```
ssh core@10.10.16.12 "sudo mkdir -p /etc/kubernetes/pki/etcd/"
ssh core@10.10.16.13 "sudo mkdir -p /etc/kubernetes/pki/etcd/"

files=(
/etc/kubernetes/pki/ca.crt
/etc/kubernetes/pki/ca.key
/etc/kubernetes/pki/sa.key
/etc/kubernetes/pki/sa.pub
/etc/kubernetes/pki/front-proxy-ca.key
/etc/kubernetes/pki/front-proxy-ca.crt
/etc/kubernetes/pki/etcd/ca.key
/etc/kubernetes/pki/etcd/ca.crt
)
mkdir -p /tmp/rsyncc/etc/kubernetes/pki/etcd/

for i in "${files[@]}"; do
rsync --rsync-path="sudo rsync" core@10.10.16.11:$i /tmp/rsyncc$i

rsync --rsync-path="sudo rsync" /tmp/rsyncc$i core@10.10.16.12:$i
rsync --rsync-path="sudo rsync" /tmp/rsyncc$i core@10.10.16.13:$i
done
```

6. Join other nodes
```
kubeadm join api.kubelius:6443 --token <token generated during first node init> --discovery-token-ca-cert-hash <sha> --control-plane --ignore-preflight-errors=NumCPU,Mem
```

7. Retrive Kubeconfig
```
rsync --rsync-path="sudo rsync" core@10.10.16.11:/etc/kubernetes/super-admin.conf /tmp/kubelius.conf
export KUBECONFIG=/tmp/kubelius.conf
kubectl get nodes
```
















lab can be created using `terraform apply` and descructed with `terraform destroy`

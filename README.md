hosting example files for a [blog post](https://georgedeblog.com/blog/labs-for-broke/)

Covering VPN part of the blog.


# Instructions

sensetive data is provided via local json file called aws_creds.json. 
```
{
  "region" : "eu-central-1",
  "access_key" : "",
  "secret_key" : "",
}
```

1. create aws_creds.json

2. generate wireguard keys
```
wg genkey > server.key
cat server.key | wg pubkey > server.pub
wg genkey > client.key
cat client.key | wg pubkey > client.pub
```

3. update butane file in ignition/vpn.bu

4. generate ignition 
```
butane vpn.bu > vpn.ign
```
5. download terraform deps
```
terraform init
```

lab can be created using `terraform apply` and descructed with `terraform destroy`

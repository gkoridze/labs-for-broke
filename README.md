hosting example files for a [blog post](https://georgedeblog.com/blog/labs-for-broke/)

Covering NAT part of the blog.


# Instructions

sensetive data is provided via local json file called aws_creds.json. 
```
{
  "region" : "eu-central-1",
  "access_key" : "",
  "secret_key" : "",
}
```
start by creating aws_creds.json and running `terraform init`

lab can be created using `terraform apply` and descructed with `terraform destroy`

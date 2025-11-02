data "local_file" "aws_creds" {
  filename = "aws_creds.json"
}

locals {
  ami = "ami-0c3ad5b862967b4f1"
  aws_creds = jsondecode(data.local_file.aws_creds.content)
}

provider "aws" {
  region = local.aws_creds.region
  access_key = local.aws_creds.access_key
  secret_key = local.aws_creds.secret_key
}

resource "aws_vpc" "lab" {
  cidr_block = "10.10.16.0/20"
}
resource "aws_subnet" "instance_subnet" {
  vpc_id = aws_vpc.lab.id
  cidr_block = "10.10.16.0/24"
}

resource "aws_subnet" "gw_subnet" {
  vpc_id = aws_vpc.lab.id
  cidr_block = "10.10.31.0/24"
}

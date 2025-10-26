data "local_file" "aws_creds" {
  filename = "aws_creds.json"
}

locals {
  ssh_key = "GK-MacP"
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


resource "aws_network_interface" "gw_int" {
  subnet_id = aws_subnet.gw_subnet.id
  private_ips = ["10.10.31.10"]
  source_dest_check = false
  security_groups = [ aws_security_group.gw_sec.id ]
} 
resource "aws_instance" "gw_instance" {
  ami = local.ami
  instance_type = "t2.micro"
  key_name = local.ssh_key
  user_data_base64 = base64encode(file("ignitions/vpn.ign"))
  network_interface {
    network_interface_id = aws_network_interface.gw_int.id
    device_index = 0
  }
}

resource "aws_eip" "nat_public_ip" {
  instance = aws_instance.gw_instance.id
  domain = "vpc"
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.lab.id
}


resource "aws_route_table" "gw_routing" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }
}

resource "aws_route_table_association" "gw_rb" {
  subnet_id      = aws_subnet.gw_subnet.id
  route_table_id = aws_route_table.gw_routing.id
}

resource "aws_security_group" "gw_sec" {
  name        = "gw_sec"
  description = "sec group for the gw server"
  vpc_id      = aws_vpc.lab.id
}

resource "aws_vpc_security_group_ingress_rule" "gw_allow_ssh" {
  security_group_id = aws_security_group.gw_sec.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "gw_allow_wireguard" {
  security_group_id = aws_security_group.gw_sec.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "udp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "gw_allow_routing" {
  security_group_id = aws_security_group.gw_sec.id
  cidr_ipv4         = "10.10.16.0/24"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "gw_allow_outbound" {
  security_group_id = aws_security_group.gw_sec.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "lab_instance" {
  count = 2
  ami = local.ami
  instance_type = "t2.micro"
  key_name = local.ssh_key
  network_interface {
    network_interface_id = aws_network_interface.instance_int[count.index].id
    device_index = 0
  }
}

resource "aws_network_interface" "instance_int" {
  count = 2
  subnet_id = aws_subnet.instance_subnet.id
  security_groups = [ aws_security_group.instance_sec.id ]
} 


resource "aws_security_group" "instance_sec" {
  name        = "instace_sec"
  description = "sec group for the instance server"
  vpc_id      = aws_vpc.lab.id
}

resource "aws_vpc_security_group_ingress_rule" "instance_allow_ssh" {
  security_group_id = aws_security_group.instance_sec.id
  cidr_ipv4         = "10.10.31.0/24"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "instance_allow_outbound" {
  security_group_id = aws_security_group.instance_sec.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_default_route_table" "instance_rtable" {

  default_route_table_id = aws_vpc.lab.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.gw_int.id
  }
}


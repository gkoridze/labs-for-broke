resource "aws_network_interface" "gw_int" {
  subnet_id         = aws_subnet.gw_subnet.id
  private_ips       = ["10.10.31.10"]
  source_dest_check = false
  security_groups   = [aws_security_group.gw_sec.id]
}
resource "aws_instance" "gw_instance" {
  ami              = local.ami
  instance_type    = "t2.micro"
  key_name         = local.aws_creds.ssh_key_pair
  user_data_base64 = data.external.ignition_vpn.result.base64
  network_interface {
    network_interface_id = aws_network_interface.gw_int.id
    device_index         = 0
  }
}

resource "aws_eip" "nat_public_ip" {
  instance = aws_instance.gw_instance.id
  domain   = "vpc"
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


data "external" "ignition_vpn" {
  program = ["sh", "scripts/butane.sh"]
  query = {
    config64 = base64encode(templatefile("templates/vpn.tftpl", {
      private_key = local.aws_creds.wg_private
      peers       = base64encode(jsonencode(local.aws_creds.wg_peers))
    }))
  }
}


output "vpn_client" {
  value = base64encode(templatefile("templates/vpn-client.tftpl", {
    peers     = base64encode(jsonencode(local.aws_creds.wg_peers))
    publickey = local.aws_creds.wg_public
    endpoint  = aws_eip.nat_public_ip.public_ip
  }))
}

output "vpn_address" {
  value = aws_eip.nat_public_ip.public_ip
}

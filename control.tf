resource "aws_instance" "control" {
  for_each = var.control-instances
  ami = local.ami
  instance_type = "t2.micro"
  key_name = local.ssh_key
  user_data_base64 = data.external.ignition_control[each.key].result.base64
  network_interface {
    network_interface_id = aws_network_interface.control_int[each.key].id
    device_index = 0
  }
}

resource "aws_network_interface" "control_int" {
  for_each = var.control-instances
  subnet_id = aws_subnet.instance_subnet.id
  security_groups = [ aws_security_group.control_sec.id ]
  private_ips = [each.value["ip"]]
  source_dest_check = false
} 


resource "aws_security_group" "control_sec" {
  name        = "control_sec"
  description = "sec group for the controller controls"
  vpc_id      = aws_vpc.lab.id
}

resource "aws_vpc_security_group_ingress_rule" "control_allow_ssh" {
  security_group_id = aws_security_group.control_sec.id
  cidr_ipv4         = "10.10.31.0/24"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "control_allow_internal" {
  security_group_id = aws_security_group.control_sec.id
  cidr_ipv4         = "10.10.16.0/24"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "control_allow_lb" {
  security_group_id = aws_security_group.control_sec.id
  cidr_ipv4         = "10.10.16.10/32"
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

resource "aws_vpc_security_group_egress_rule" "control_allow_outbound" {
  security_group_id = aws_security_group.control_sec.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_default_route_table" "control_rtable" {

  default_route_table_id = aws_vpc.lab.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.gw_int.id
  }
}

data "external" "ignition_control" {
  for_each = var.control-instances
  program = ["sh", "scripts/butane.sh"]
  query = {
    config64 = base64encode(templatefile("templates/control.tftpl", {
      name = each.key
    }))
  }
}


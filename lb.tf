resource "aws_security_group" "kube_lb" {
  name        = "kube_lb"
  description = "sec group for the lb server"
  vpc_id      = aws_vpc.lab.id
  tags = {
    Name = "kube_lb"
  }
}


resource "aws_vpc_security_group_ingress_rule" "kube_lb_allow_kapi" {
  security_group_id = aws_security_group.kube_lb.id
  cidr_ipv4         = "10.10.16.0/24"
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

resource "aws_vpc_security_group_ingress_rule" "kube_lb_allow_kapi_p" {
  security_group_id = aws_security_group.kube_lb.id
  cidr_ipv4         = "10.10.31.0/24"
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

resource "aws_vpc_security_group_egress_rule" "kube_lb_allow_outbound" {
  security_group_id = aws_security_group.kube_lb.id
  cidr_ipv4         = "10.10.16.0/20"
  ip_protocol       = "-1"
}

resource "aws_lb" "kube" { 
  name               = "kube"
  load_balancer_type = "network"
  internal = true
  security_groups    = [ aws_security_group.kube_lb.id ]
  subnet_mapping { 
    subnet_id = aws_subnet.instance_subnet.id
    private_ipv4_address = "10.10.16.10" 
  }

}

resource "aws_lb_target_group" "kube-control" {
  name        = "kube-control"
  port        = 6443
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.lab.id
  ip_address_type = "ipv4"
  health_check {
    port     = 6443
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "kube_api" {
  load_balancer_arn = aws_lb.kube.arn
  port = 6443
  protocol = "TCP"
  default_action {
     type             = "forward"
     target_group_arn = aws_lb_target_group.kube-control.arn
  }
}

resource "aws_lb_target_group_attachment" "kube-controlers" {
  for_each = aws_network_interface.control_int
  target_group_arn = aws_lb_target_group.kube-control.arn
  target_id =  each.value.private_ip
  port = 6443
}


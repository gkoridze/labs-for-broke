resource "aws_instance" "control" {
  for_each             = var.control-instances
  ami                  = local.ami
  instance_type        = "t2.micro"
  key_name             = local.aws_creds.ssh_key_pair
  user_data_base64     = data.external.ignition_append[each.key].result.base64
  iam_instance_profile = aws_iam_instance_profile.control_instances.name
  network_interface {
    network_interface_id = aws_network_interface.control_int[each.key].id
    device_index         = 0
  }
}

resource "aws_iam_instance_profile" "control_instances" {
  name = "kubelius-instances"
  role = aws_iam_role.ignition_role.name
}


resource "aws_network_interface" "control_int" {
  for_each          = var.control-instances
  subnet_id         = aws_subnet.instance_subnet.id
  security_groups   = [aws_security_group.control_sec.id]
  private_ips       = [each.value["ip"]]
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
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.gw_int.id
  }
}


data "external" "ignition_control" {
  for_each = var.control-instances
  program  = ["sh", "scripts/butane.sh"]

  query = {
    config64 = base64encode(templatefile("templates/control.tftpl", {
      ip   = each.value["ip"], name = each.key, images = { etcd-image = var.static-pods.etcd-image, api-image = var.static-pods.api-image, scheduler-image = var.static-pods.scheduler-image, controller-image = var.static-pods.controller-image }
      ca64 = base64encode(tls_locally_signed_cert.kubernetes-ca.cert_pem)
      certs = {
        "/etc/kubernetes/pki/etcd/server.crt"              = base64encode(tls_locally_signed_cert.etcd-server[each.key].cert_pem)
        "/etc/kubernetes/pki/etcd/server.key"              = base64encode(tls_private_key.etcd-server[each.key].private_key_pem)
        "/etc/kubernetes/pki/etcd/peer.crt"                = base64encode(tls_locally_signed_cert.etcd-peer[each.key].cert_pem)
        "/etc/kubernetes/pki/etcd/peer.key"                = base64encode(tls_private_key.etcd-peer[each.key].private_key_pem)
        "/etc/kubernetes/pki/etcd/ca.crt"                  = base64encode(tls_locally_signed_cert.etcd-ca.cert_pem)
        "/etc/kubernetes/pki/ca.crt"                       = base64encode(tls_locally_signed_cert.kubernetes-ca.cert_pem)
        "/etc/kubernetes/pki/ca.key"                       = base64encode(tls_private_key.kubernetes-ca.private_key_pem)
        "/etc/kubernetes/pki/apiserver-etcd-client.crt"    = base64encode(tls_locally_signed_cert.kube-apiserver-etcd-client.cert_pem)
        "/etc/kubernetes/pki/apiserver-etcd-client.key"    = base64encode(tls_private_key.kube-apiserver-etcd-client.private_key_pem)
        "/etc/kubernetes/pki/apiserver-kubelet-client.crt" = base64encode(tls_locally_signed_cert.kube-apiserver-kubelet.cert_pem)
        "/etc/kubernetes/pki/apiserver-kubelet-client.key" = base64encode(tls_private_key.kube-apiserver-kubelet.private_key_pem)
        "/etc/kubernetes/pki/sa.key"                       = base64encode(tls_private_key.service-account.private_key_pem)
        "/etc/kubernetes/pki/sa.pub"                       = base64encode(tls_private_key.service-account.public_key_pem)
        "/etc/kubernetes/pki/apiserver.key"                = base64encode(tls_private_key.kube-apiserver[each.key].private_key_pem)
        "/etc/kubernetes/pki/apiserver.crt"                = base64encode(tls_locally_signed_cert.kube-apiserver[each.key].cert_pem)
      }
      client-certs = {
        kubelet            = { cert = base64encode(tls_locally_signed_cert.kubelet[each.key].cert_pem), key = base64encode(tls_private_key.kubelet[each.key].private_key_pem), user = "system:node:${each.key}" }
        scheduler          = { cert = base64encode(tls_locally_signed_cert.scheduler.cert_pem), key = base64encode(tls_private_key.scheduler.private_key_pem), user = "system:kube-scheduler" }
        controller-manager = { cert = base64encode(tls_locally_signed_cert.controller.cert_pem), key = base64encode(tls_private_key.controller.private_key_pem), user = "system:kube-scheduler" }
      }
    }))
  }
}

data "external" "ignition_append" {
  for_each = var.control-instances
  program  = ["sh", "scripts/butane.sh"]
  query = {
    config64 = base64encode(templatefile("templates/control-append.tftpl", { key = each.key
      bucket   = aws_s3_bucket.ignitions.id
      checksum = aws_s3_object.control-ignition[each.key].checksum_sha256
    }))
  }
}



output "superadmin64" {
  sensitive = true
  value     = base64encode(templatefile("templates/super-admin.tftpl", { ca = base64encode(join("\n", [tls_self_signed_cert.root-ca.cert_pem, tls_locally_signed_cert.kubernetes-ca.cert_pem])), crt = base64encode(tls_locally_signed_cert.kube-super-admin.cert_pem), key = base64encode(tls_private_key.kube-super-admin.private_key_pem) }))
}

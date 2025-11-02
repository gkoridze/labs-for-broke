resource "tls_private_key" "kube-super-admin" {
  algorithm = "RSA"                                                                                                             
  rsa_bits  = 2048                                              
}

resource "tls_cert_request" "kube-super-admin" {
  private_key_pem = tls_private_key.kube-super-admin.private_key_pem

  subject {
    common_name  = "kubernetes-super-admin"
    organization = "system:masters"
  }
}


resource "tls_private_key" "kubelet" {
  for_each = local.nodes_merge
  algorithm = "RSA"                                                                                                             
  rsa_bits  = 2048                                              
}

resource "tls_private_key" "scheduler" {
  algorithm = "RSA"                                                                                                             
  rsa_bits  = 2048                                              
}

resource "tls_private_key" "controller" {
  algorithm = "RSA"                                                                                                             
  rsa_bits  = 2048                                              
}

resource "tls_cert_request" "kubelet" {
  for_each = local.nodes_merge
  private_key_pem = tls_private_key.kubelet[each.key].private_key_pem

  subject {
    common_name  = "system:node:${each.key}"
    organization = "system:nodes"
  }
}

resource "tls_cert_request" "scheduler" {
  private_key_pem = tls_private_key.scheduler.private_key_pem

  subject {
    common_name  = "system:kube-scheduler"
  }
}

resource "tls_cert_request" "controller" {
  private_key_pem = tls_private_key.controller.private_key_pem

  subject {
    common_name  = "system:kube-controller-manager"
  }
}

locals {
  nodes_merge = merge(var.control-instances)
}

resource "tls_locally_signed_cert" "kubelet" {
  for_each = local.nodes_merge
  cert_request_pem   = tls_cert_request.kubelet[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.kubernetes-ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.kubernetes-ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "digital_signature",
    "client_auth",
    "key_encipherment",
  ]
}

resource "tls_locally_signed_cert" "scheduler" {
  cert_request_pem   = tls_cert_request.scheduler.cert_request_pem
  ca_private_key_pem = tls_private_key.kubernetes-ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.kubernetes-ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "digital_signature",
    "client_auth",
    "key_encipherment",
  ]
}

resource "tls_locally_signed_cert" "controller" {
  cert_request_pem   = tls_cert_request.controller.cert_request_pem
  ca_private_key_pem = tls_private_key.kubernetes-ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.kubernetes-ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "digital_signature",
    "client_auth",
    "key_encipherment",
  ]
}


resource "tls_locally_signed_cert" "kube-super-admin" {
  cert_request_pem   = tls_cert_request.kube-super-admin.cert_request_pem
  ca_private_key_pem = tls_private_key.kubernetes-ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.kubernetes-ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "digital_signature",
    "client_auth",
    "key_encipherment",
  ]
}

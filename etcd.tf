resource "tls_private_key" "etcd-server" {
  for_each  = var.control-instances
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "etcd-peer" {
  for_each  = var.control-instances
  algorithm = "RSA"
  rsa_bits  = 2048
}



resource "tls_cert_request" "etcd-server" {
  for_each        = var.control-instances
  private_key_pem = tls_private_key.etcd-server[each.key].private_key_pem

  subject {
    common_name  = each.key
    organization = "Kubelius totallyacorp"
  }
  ip_addresses = [each.value["ip"], "127.0.0.1"]
  dns_names    = [each.key]
}

resource "tls_cert_request" "etcd-peer" {
  for_each        = var.control-instances
  private_key_pem = tls_private_key.etcd-peer[each.key].private_key_pem

  subject {
    common_name = each.key
  }
  ip_addresses = [each.value["ip"]]
  dns_names    = [each.key]
}


resource "tls_locally_signed_cert" "etcd-server" {
  for_each           = var.control-instances
  cert_request_pem   = tls_cert_request.etcd-server[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.etcd-ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.etcd-ca.cert_pem

  validity_period_hours = 8766

  allowed_uses = [
    "digital_signature",
    "server_auth",
    "client_auth",
    "key_encipherment",
  ]
}

resource "tls_locally_signed_cert" "etcd-peer" {
  for_each           = var.control-instances
  cert_request_pem   = tls_cert_request.etcd-peer[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.etcd-ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.etcd-ca.cert_pem

  validity_period_hours = 8766

  allowed_uses = [
    "digital_signature",
    "server_auth",
    "client_auth",
    "key_encipherment",
  ]
}


resource "tls_private_key" "kube-apiserver" {
  for_each  = var.control-instances
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "kube-apiserver-kubelet" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "kube-apiserver-etcd-client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}


resource "tls_cert_request" "kube-apiserver" {
  for_each        = var.control-instances
  private_key_pem = tls_private_key.kube-apiserver[each.key].private_key_pem

  subject {
    common_name = each.key
  }
  ip_addresses = [each.value["ip"], "10.10.16.10", "10.96.0.1"]
  dns_names    = [each.key, "api.kubelius", "kubernetes", "kubernetes.default", "kubernetes.default.svc", "kubernetes.default.svc.cluster.local"]
}

resource "tls_cert_request" "kube-apiserver-kubelet" {
  private_key_pem = tls_private_key.kube-apiserver-kubelet.private_key_pem

  subject {
    common_name  = "kube-apiserver-kubelet"
    organization = "system:masters"
  }
}

resource "tls_cert_request" "kube-apiserver-etcd-client" {
  private_key_pem = tls_private_key.kube-apiserver-etcd-client.private_key_pem

  subject {
    common_name = "kube-apiserver-etcd-client"
  }

}


resource "tls_locally_signed_cert" "kube-apiserver" {
  for_each           = var.control-instances
  cert_request_pem   = tls_cert_request.kube-apiserver[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.kubernetes-ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.kubernetes-ca.cert_pem

  validity_period_hours = 8766

  allowed_uses = [
    "digital_signature",
    "server_auth",
    "key_encipherment",
  ]
}

resource "tls_locally_signed_cert" "kube-apiserver-etcd-client" {
  cert_request_pem   = tls_cert_request.kube-apiserver-etcd-client.cert_request_pem
  ca_private_key_pem = tls_private_key.etcd-ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.etcd-ca.cert_pem

  validity_period_hours = 8766

  allowed_uses = [
    "digital_signature",
    "client_auth",
    "key_encipherment",
  ]
}

resource "tls_locally_signed_cert" "kube-apiserver-kubelet" {
  cert_request_pem   = tls_cert_request.kube-apiserver-kubelet.cert_request_pem
  ca_private_key_pem = tls_private_key.kubernetes-ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.kubernetes-ca.cert_pem

  validity_period_hours = 8766

  allowed_uses = [
    "digital_signature",
    "client_auth",
    "key_encipherment",
  ]
}

resource "tls_private_key" "service-account" {
  algorithm = "RSA"
  rsa_bits  = 2048
}


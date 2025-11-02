resource "tls_private_key" "root-ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "tls_self_signed_cert" "root-ca" {
   private_key_pem = tls_private_key.root-ca.private_key_pem

   is_ca_certificate = true

   subject {
     common_name  = "root-ca"
   }
    
  validity_period_hours = 43830 #5 Years.

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

resource "tls_private_key" "etcd-ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
  
resource "tls_cert_request" "etcd-ca" {
  private_key_pem = tls_private_key.etcd-ca.private_key_pem

  subject {
    common_name  = "etcd-ca"
  }
}

resource "tls_locally_signed_cert" "etcd-ca" {
  cert_request_pem   = tls_cert_request.etcd-ca.cert_request_pem
  ca_private_key_pem = tls_private_key.root-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root-ca.cert_pem

  is_ca_certificate = true

  validity_period_hours = 26298

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}



resource "tls_private_key" "kubernetes-ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
  
resource "tls_cert_request" "kubernetes-ca" {
  private_key_pem = tls_private_key.kubernetes-ca.private_key_pem

  subject {
    common_name  = "kubernetes-ca"
  }
}

resource "tls_locally_signed_cert" "kubernetes-ca" {
  cert_request_pem   = tls_cert_request.kubernetes-ca.cert_request_pem
  ca_private_key_pem = tls_private_key.root-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root-ca.cert_pem

  is_ca_certificate = true

  validity_period_hours = 26298

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

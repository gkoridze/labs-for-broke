variable "control-instances" {
  type = map
  default = {
    control-01 = { ip = "10.10.16.11" },
    control-02 = { ip = "10.10.16.12" },
    control-03 = { ip = "10.10.16.13" },
  }
}

variable "static-pods" {
  type = map
  default = {
    etcd-image = "registry.k8s.io/etcd:3.5.21-0",
    api-image = "registry.k8s.io/kube-apiserver:v1.33.0",
    scheduler-image = "registry.k8s.io/kube-scheduler:v1.33.0",
    controller-image = "registry.k8s.io/kube-controller-manager:v1.33.0"
  }
}


variable "control-instances" {
  type = map
  default = {
    control-01 = { ip = "10.10.16.11" },
    control-02 = { ip = "10.10.16.12" },
    control-03 = { ip = "10.10.16.13" },
  }
}

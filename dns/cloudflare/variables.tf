locals {
  default_ttl = 60

  mx_records = [
    {
      value    = "route1.mx.cloudflare.net"
      priority = 97
    },
    {
      value    = "route2.mx.cloudflare.net"
      priority = 5
    },
    {
      value    = "route3.mx.cloudflare.net"
      priority = 15
    }
  ]

  txt_records = [
    "v=spf1 include:_spf.mx.cloudflare.net ~all"
  ]
}


variable "CLOUDFLARE_API_TOKEN" {
  tpye      = string
  sensitive = true
}

variable "CLOUDFLARE_ZONE_ID" {
  type = string
}

variable "PRIMARY_DOMAIN_EXT_IP" {
  type = string
}

variable "PRIMARY_DOMAIN" {
  type = string
}

variable "ROOT_CNAMES" {
  type = list()
}

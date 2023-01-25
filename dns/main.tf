terraform {
  backend "remote" {
    organization = "steveharsant"
    workspaces {
      name = "infra"
    }
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}

resource "cloudflare_record" "a_root" {
  zone_id         = var.CLOUDFLARE_ZONE_ID
  type            = "A"
  name            = "@"
  value           = var.PRIMARY_DOMAIN_EXT_IP
  allow_overwrite = true
  proxied         = false
  ttl             = local.default_ttl

}

resource "cloudflare_record" "root_cnames" {
  for_each = toset(var.ROOT_CNAMES)

  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = each.key
  value   = var.primary_domain
  type    = "CNAME"
  ttl     = local.default_ttl
  proxied = false
}

resource "cloudflare_record" "mx_routing" {
  for_each = {
    for index, record in local.mx_records :
    record.value => value
  }

  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = var.PRIMARY_DOMAIN
  type    = "MX"
  ttl     = local.default_ttl
  proxied = false
}

resource "cloudflare_record" "txt" {
  for_each = toset(local.txt_records)

  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = var.PRIMARY_DOMAIN
  value   = each.key
  type    = "TXT"
  ttl     = local.default_ttl
  proxied = false
}

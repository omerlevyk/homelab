locals {
  sorted_hostnames = sort(keys(var.public_hostnames))
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.account_id
  tunnel_id  = var.tunnel_id

  config = {
    ingress = concat(
      [
        for subdomain in local.sorted_hostnames : {
          hostname = "${subdomain}.${var.zone_name}"
          service  = var.public_hostnames[subdomain].service
        }
      ],
      [
        {
          service = "http_status:404"
        }
      ]
    )
  }
}

resource "cloudflare_dns_record" "tunnel_cname" {
  for_each = var.public_hostnames

  zone_id = var.zone_id
  name    = each.key
  type    = "CNAME"
  content = "${var.tunnel_id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}


variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID."
  type        = string
}

variable "zone_name" {
  description = "Cloudflare zone name, for example example.com."
  type        = string
}

variable "tunnel_id" {
  description = "Cloudflare tunnel UUID."
  type        = string
}

variable "public_hostnames" {
  description = "Map of subdomain => backend service URL."
  type = map(object({
    service = string
  }))
}


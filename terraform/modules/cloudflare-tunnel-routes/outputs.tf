output "hostnames" {
  description = "Managed public hostnames."
  value       = [for subdomain in sort(keys(var.public_hostnames)) : "${subdomain}.${var.zone_name}"]
}


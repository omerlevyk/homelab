variable "kubeconfig_path" {
  description = "Path to kubeconfig used by Terraform providers."
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Optional kubeconfig context. Null uses the current context in kubeconfig."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Logical cluster name label used in metadata and outputs."
  type        = string
  default     = "homeserver2-k3s"
}

variable "enable_argocd_bootstrap" {
  description = "Set true after adding the ArgoCD module implementation."
  type        = bool
  default     = false
}

variable "argocd_chart_version" {
  description = "Optional ArgoCD chart version. Null means latest available."
  type        = string
  default     = null
}

variable "enable_cloudflare_tunnel_routes" {
  description = "Set true to manage Cloudflare tunnel ingress + DNS records via Terraform."
  type        = bool
  default     = false
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the Zero Trust tunnel."
  type        = string
  default     = null
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for your public domain."
  type        = string
  default     = null
}

variable "cloudflare_zone_name" {
  description = "Cloudflare zone name, for example example.com."
  type        = string
  default     = null
}

variable "cloudflare_tunnel_id" {
  description = "Existing Cloudflare tunnel UUID used by cloudflared in-cluster."
  type        = string
  default     = null
}

variable "cloudflare_public_hostnames" {
  description = "Map of subdomain => backend service URL for tunnel ingress."
  type = map(object({
    service = string
  }))
  default = {}
}

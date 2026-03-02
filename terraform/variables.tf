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
  default     = "homeserver-k3s"
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

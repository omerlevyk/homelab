variable "namespace" {
  description = "Namespace where ArgoCD will be installed."
  type        = string
  default     = "infra"
}

variable "release_name" {
  description = "Helm release name for ArgoCD."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Optional ArgoCD chart version. Null means latest from the repository."
  type        = string
  default     = null
}

variable "create_namespace" {
  description = "Whether Helm should create namespace."
  type        = bool
  default     = false
}


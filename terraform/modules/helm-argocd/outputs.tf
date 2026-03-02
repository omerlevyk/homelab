output "release_name" {
  description = "ArgoCD Helm release name."
  value       = helm_release.argocd.name
}

output "namespace" {
  description = "Namespace where ArgoCD was installed."
  value       = helm_release.argocd.namespace
}


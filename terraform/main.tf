locals {
  namespaces = toset(["infra", "dns", "apps", "obs"])
}

resource "kubernetes_namespace_v1" "core" {
  for_each = local.namespaces

  metadata {
    name = each.value
    labels = {
      "homelab.omer/managed-by" = "terraform"
      "homelab.omer/cluster"    = var.cluster_name
    }
  }
}

output "managed_namespaces" {
  description = "Namespaces currently managed by Terraform."
  value       = sort([for ns in kubernetes_namespace_v1.core : ns.metadata[0].name])
}

module "helm_argocd" {
  source = "./modules/helm-argocd"
  count  = var.enable_argocd_bootstrap ? 1 : 0

  namespace        = "infra"
  release_name     = "argocd"
  chart_version    = var.argocd_chart_version
  create_namespace = false

  depends_on = [kubernetes_namespace_v1.core]
}

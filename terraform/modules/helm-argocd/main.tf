resource "helm_release" "argocd" {
  name             = var.release_name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  # Keep this installation minimal; ingress/routing is handled separately.
  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = "true"
        }
      }
      server = {
        service = {
          type = "ClusterIP"
        }
      }
    })
  ]

}

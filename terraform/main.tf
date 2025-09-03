provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

terraform {
  required_providers {
    null       = { source = "hashicorp/null", version = "~> 3.2" }
    helm       = { source = "hashicorp/helm", version = "~> 3.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.38" }
    time       = { source = "hashicorp/time", version = "~> 0.11" }
    kubectl    = { source = "gavinbunney/kubectl", version = "~> 1.14" }
  }
}

# Provision a Minikube Cluster
resource "null_resource" "minikube_cluster" {
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      minikube start --driver=docker --container-runtime=containerd --nodes=1 --cni=calico --install-addons=false --kubernetes-version=v1.28.3 --apiserver-ips=127.0.0.1 --embed-certs=true --force=true
      minikube update-context
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sudo sh -c 'minikube delete'"
  }
}

# Istio Base & Istiod
resource "helm_release" "istio_base" {
  depends_on       = [null_resource.minikube_cluster]
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
}

resource "helm_release" "istiod" {
  depends_on = [helm_release.istio_base]
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  values = [
    <<-EOT
    global:
      hub: gcr.io/istio-release
      tag: 1.20.0
    meshConfig:
      accessLogFile: "/dev/stdout"
    EOT
  ]
}

# ArgoCD
resource "helm_release" "argocd" {
  depends_on       = [null_resource.minikube_cluster, helm_release.istiod]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
}

# Delay for CRD registration
resource "time_sleep" "wait_for_argocd_crds" {
  depends_on      = [helm_release.argocd]
  create_duration = "30s"
}

# Prometheus and Grafana
resource "helm_release" "prometheus" {
  depends_on       = [null_resource.minikube_cluster, helm_release.istiod]
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
}

resource "kubectl_manifest" "my_app_argocd" {
  depends_on = [time_sleep.wait_for_argocd_crds]

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "my-gitops-app"
      namespace = "argocd"
    }
    spec = {
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      project = "default"
      source = {
        repoURL        = "https://github.com/kiranrajeev1/cicd-for-gitops-istio-deployment.git"
        targetRevision = "main"
        path           = "manifests/my-app"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  })
}

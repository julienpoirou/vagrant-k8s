# vagrant-k8s

Plugin Vagrant pour piloter un cluster Kubernetes depuis la machine hôte, avec des provisionneurs Helm et Kustomize.

## Installation

```sh
vagrant plugin install vagrant-k8s
```

## Configuration du cluster

```ruby
Vagrant.configure("2") do |config|
  config.k8s.kubeconfig = "config/kubeconfig.yaml" # relatif au Vagrantfile
  config.k8s.context    = "kind-dev"
  config.k8s.namespace  = "demo"
  config.k8s.kubectl    = "kubectl"               # facultatif
end
```

Laissez `kubeconfig` à `nil` pour utiliser la configuration habituelle de Kubectl (dont `KUBECONFIG`).

## Provisionneur Helm

```ruby
config.vm.provision "nginx", type: "helm" do |helm|
  helm.release = "nginx"
  helm.chart = "ingress-nginx"
  helm.repo = "https://kubernetes.github.io/ingress-nginx"
  helm.version = "4.11.3"
  helm.namespace = "ingress-nginx"
  helm.create_namespace = true
  helm.values = ["k8s/ingress-values.yaml"]
  helm.set = { "controller.replicaCount" => 2 }
  helm.wait = true
  helm.atomic = true
  helm.timeout = "5m"
end
```

Le provisionneur exécute `helm upgrade --install` sur le contexte configuré dans `config.k8s`.

## Provisionneur Kustomize

```ruby
config.vm.provision "application", type: "kustomize" do |kustomize|
  kustomize.path = "k8s/overlays/dev"
  kustomize.namespace = "demo" # remplace config.k8s.namespace
  kustomize.server_side = true
  kustomize.prune = true
  kustomize.prune_selector = "app.kubernetes.io/managed-by=vagrant"
  kustomize.wait = true
end
```

Il exécute `kubectl apply -k`. Avec `wait`, il attend les pods prêts pendant cinq minutes.

## Prérequis

`kubectl` est requis sur l'hôte. Helm est requis uniquement pour le provisionneur Helm. Les chemins de manifests et de fichiers values sont relatifs au répertoire du Vagrantfile.

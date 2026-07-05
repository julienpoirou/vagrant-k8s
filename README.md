# vagrant-k8s

[![CI](https://github.com/julienpoirou/vagrant-k8s/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/julienpoirou/vagrant-k8s/actions/workflows/ci.yml)
[![CodeQL](https://github.com/julienpoirou/vagrant-k8s/actions/workflows/codeql.yml/badge.svg)](https://github.com/julienpoirou/vagrant-k8s/actions/workflows/codeql.yml)
[![Release](https://img.shields.io/github/v/release/julienpoirou/vagrant-k8s?include_prereleases&sort=semver)](https://github.com/julienpoirou/vagrant-k8s/releases)
[![RubyGems](https://img.shields.io/gem/v/vagrant-k8s.svg)](https://rubygems.org/gems/vagrant-k8s)
[![License](https://img.shields.io/github/license/julienpoirou/vagrant-k8s.svg)](LICENSE.md)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196.svg)](https://www.conventionalcommits.org)
[![Renovate](https://img.shields.io/badge/Renovate-enabled-brightgreen.svg)](https://renovatebot.com)
[![Total downloads](https://img.shields.io/gem/dt/vagrant-k8s?logo=rubygems&label=downloads)](https://rubygems.org/gems/vagrant-k8s)

Vagrant plugin to drive a Kubernetes cluster from the host machine, with Helm and Kustomize provisioners.

See [the French documentation](README.fr.md) for the same content in French.

## Installation

```sh
vagrant plugin install vagrant-k8s
```

## Cluster configuration

```ruby
Vagrant.configure("2") do |config|
  config.k8s.kubeconfig = "config/kubeconfig.yaml" # relative to the Vagrantfile
  config.k8s.context    = "kind-dev"
  config.k8s.namespace  = "demo"
  config.k8s.kubectl    = "kubectl"               # optional
end
```

Leave `kubeconfig` at `nil` to use the usual Kubectl configuration (including `KUBECONFIG`).

## Helm provisioner

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

The provisioner runs `helm upgrade --install` against the context configured in `config.k8s`.

## Kustomize provisioner

```ruby
config.vm.provision "application", type: "kustomize" do |kustomize|
  kustomize.path = "k8s/overlays/dev"
  kustomize.namespace = "demo" # overrides config.k8s.namespace
  kustomize.server_side = true
  kustomize.prune = true
  kustomize.prune_selector = "app.kubernetes.io/managed-by=vagrant"
  kustomize.wait = true
end
```

It runs `kubectl apply -k`. With `wait`, it waits for pods to become ready for five minutes.

## Requirements

`kubectl` is required on the host. Helm is required only for the Helm provisioner. Manifest and values file paths are relative to the Vagrantfile directory.

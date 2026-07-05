# frozen_string_literal: true

require 'vagrant'
require 'pathname'
require_relative 'config'
require_relative 'helm_provisioner'
require_relative 'kustomize_provisioner'

module VagrantK8s
  class Plugin < Vagrant.plugin('2')
    name 'vagrant-k8s'

    config(:k8s) { Config }
    config(:helm, :provisioner) { HelmConfig }
    provisioner(:helm) { HelmProvisioner }
    config(:kustomize, :provisioner) { KustomizeConfig }
    provisioner(:kustomize) { KustomizeProvisioner }
  end
end

# frozen_string_literal: true

require_relative 'provisioner'

module VagrantK8s
  class KustomizeConfig < Vagrant.plugin('2', :config)
    attr_accessor :path, :namespace, :prune, :prune_selector, :server_side, :force_conflicts, :wait

    def initialize
      @path = @namespace = @prune_selector = UNSET_VALUE
      @prune = @server_side = @force_conflicts = @wait = UNSET_VALUE
    end

    def finalize!
      @namespace = nil if @namespace == UNSET_VALUE
      @prune_selector = nil if @prune_selector == UNSET_VALUE
      @prune = false if @prune == UNSET_VALUE
      @server_side = false if @server_side == UNSET_VALUE
      @force_conflicts = false if @force_conflicts == UNSET_VALUE
      @wait = false if @wait == UNSET_VALUE
    end

    def validate(_machine)
      errors = []
      errors << 'kustomize.path is required' unless @path.is_a?(String) && !@path.empty?
      if @prune && !Kubeconfig.present?(@prune_selector)
        errors << 'kustomize.prune_selector is required when prune is true'
      end
      { 'vagrant-k8s' => errors }
    end
  end

  class KustomizeProvisioner < BaseProvisioner
    def provision
      command = Kubeconfig.kubectl_command(@machine, ['apply', '-k', root_path(@config.path)],
                                           namespace: @config.namespace)
      command << '--server-side' if @config.server_side
      command << '--force-conflicts' if @config.force_conflicts
      command += ['--prune', '--selector', @config.prune_selector] if @config.prune
      run(command)
      return unless @config.wait

      # A kustomization may apply only non-pod resources (e.g. a ConfigMap), in
      # which case `kubectl wait pod --all` exits non-zero with "no matching
      # resources found". That's nothing to wait for, not a failure.
      run(Kubeconfig.kubectl_command(@machine, ['wait', '--for=condition=ready', 'pod', '--all', '--timeout=300s'],
                                     namespace: @config.namespace),
          tolerate: /no matching resources found/i,
          tolerate_message: 'No pods to wait for — the kustomization applied no pod-bearing resources.')
    end
  end
end

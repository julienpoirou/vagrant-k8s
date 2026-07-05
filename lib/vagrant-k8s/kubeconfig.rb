# frozen_string_literal: true

module VagrantK8s
  module Kubeconfig
    module_function

    # Builds a kubectl command line from cluster config and per-call overrides.
    #
    # A namespace or context passed by the caller takes precedence over the
    # `k8s` block, so provisioners can target a different context without
    # forcing that override onto every other command.
    #
    # @param machine [Vagrant::Machine] Machine whose `k8s` config supplies defaults.
    # @param extra_args [Array<String>] Arguments appended after the global flags.
    # @param namespace [String, nil] Namespace override.
    # @param context [String, nil] Context override.
    # @return [Array<String>] Complete kubectl command line.
    def kubectl_command(machine, extra_args, namespace: nil, context: nil)
      config = machine.config.k8s
      command = [config.kubectl]
      kubeconfig = resolve_path(machine, config.kubeconfig)
      command += ['--kubeconfig', kubeconfig] if kubeconfig
      selected_context = context || config.context
      selected_namespace = namespace || config.namespace
      command += ['--context', selected_context] if present?(selected_context)
      command += ['--namespace', selected_namespace] if present?(selected_namespace)
      command + extra_args
    end

    def resolve_path(machine, path)
      return nil unless present?(path)
      return path if Pathname.new(path).absolute?

      File.expand_path(path, machine.env.root_path.to_s)
    end

    def present?(value)
      value.is_a?(String) && !value.empty?
    end
  end
end

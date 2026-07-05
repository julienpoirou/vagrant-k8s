# frozen_string_literal: true

module VagrantK8s
  module Kubeconfig
    module_function

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

# frozen_string_literal: true

module VagrantK8s
  # Vagrant configuration for connecting to a Kubernetes cluster.
  #
  # @!attribute kubeconfig
  #   @return [String, nil] Path to the kubeconfig file, relative to the Vagrantfile.
  # @!attribute context
  #   @return [String, nil] Kubeconfig context used for kubectl and Helm commands.
  # @!attribute namespace
  #   @return [String, nil] Default namespace for kubectl and Helm commands.
  # @!attribute kubectl
  #   @return [String] Path to the kubectl executable.
  class Config < Vagrant.plugin('2', :config)
    attr_accessor :kubeconfig, :context, :namespace, :kubectl

    def initialize
      @kubeconfig = UNSET_VALUE
      @context = UNSET_VALUE
      @namespace = UNSET_VALUE
      @kubectl = UNSET_VALUE
    end

    def finalize!
      @kubeconfig = nil if @kubeconfig == UNSET_VALUE
      @context = nil if @context == UNSET_VALUE
      @namespace = nil if @namespace == UNSET_VALUE
      @kubectl = 'kubectl' if @kubectl == UNSET_VALUE
    end

    def validate(_machine)
      errors = []
      errors << 'k8s.kubeconfig must be a path string or nil' unless @kubeconfig.nil? || @kubeconfig.is_a?(String)
      errors << 'k8s.context must be a string or nil' unless @context.nil? || @context.is_a?(String)
      errors << 'k8s.namespace must be a string or nil' unless @namespace.nil? || @namespace.is_a?(String)
      errors << 'k8s.kubectl must be a command string' unless @kubectl.is_a?(String) && !@kubectl.empty?
      { 'vagrant-k8s' => errors }
    end
  end
end

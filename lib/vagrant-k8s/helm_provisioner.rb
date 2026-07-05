# frozen_string_literal: true

require 'open3'
require_relative 'provisioner'

module VagrantK8s
  # Vagrant provisioner configuration for `helm upgrade --install`.
  #
  # @!attribute release
  #   @return [String] Helm release name.
  # @!attribute chart
  #   @return [String] Chart reference, e.g. `repo/chart` or a local path.
  # @!attribute repo
  #   @return [String, nil] Chart repository URL, passed as `--repo`.
  # @!attribute version
  #   @return [String, nil] Chart version to install.
  # @!attribute namespace
  #   @return [String, nil] Target namespace; falls back to `k8s.namespace`.
  # @!attribute values
  #   @return [Array<String>] Values files, relative to the Vagrantfile.
  # @!attribute set
  #   @return [Hash] Individual values passed as repeated `--set key=value`.
  # @!attribute wait
  #   @return [Boolean] Whether to pass `--wait`.
  # @!attribute atomic
  #   @return [Boolean] Whether to roll back automatically on a failed install.
  # @!attribute create_namespace
  #   @return [Boolean] Whether to pass `--create-namespace`.
  # @!attribute timeout
  #   @return [String, nil] Helm timeout, e.g. `"5m"`.
  # @!attribute helm
  #   @return [String] Path to the helm executable.
  class HelmConfig < Vagrant.plugin('2', :config)
    attr_accessor :release, :chart, :repo, :version, :namespace, :values, :set, :wait, :atomic, :create_namespace,
                  :timeout, :helm

    def initialize
      @release = @chart = UNSET_VALUE
      @repo = @version = @namespace = UNSET_VALUE
      @values = @set = UNSET_VALUE
      @wait = @atomic = @create_namespace = @timeout = @helm = UNSET_VALUE
    end

    def finalize!
      @repo = nil if @repo == UNSET_VALUE
      @version = nil if @version == UNSET_VALUE
      @namespace = nil if @namespace == UNSET_VALUE
      @values = [] if @values == UNSET_VALUE
      @set = {} if @set == UNSET_VALUE
      @wait = false if @wait == UNSET_VALUE
      @atomic = false if @atomic == UNSET_VALUE
      @create_namespace = false if @create_namespace == UNSET_VALUE
      @timeout = nil if @timeout == UNSET_VALUE
      @helm = 'helm' if @helm == UNSET_VALUE
    end

    def validate(_machine)
      errors = []
      errors << 'helm.release is required' unless @release.is_a?(String) && !@release.empty?
      errors << 'helm.chart is required' unless @chart.is_a?(String) && !@chart.empty?
      errors << 'helm.values must be an array' unless @values.is_a?(Array)
      errors << 'helm.set must be a hash' unless @set.is_a?(Hash)
      { 'vagrant-k8s' => errors }
    end
  end

  class HelmProvisioner < BaseProvisioner
    def provision
      command = [@config.helm, 'upgrade', '--install', @config.release, @config.chart]
      append_release_options(command)
      append_values_and_set(command)
      append_cluster_options(command)
      run(command)
    end

    private

    def append_release_options(command)
      command.push('--repo', @config.repo) if Kubeconfig.present?(@config.repo)
      command.push('--version', @config.version) if Kubeconfig.present?(@config.version)
      namespace = @config.namespace || @machine.config.k8s.namespace
      command.push('--namespace', namespace) if Kubeconfig.present?(namespace)
      command << '--create-namespace' if @config.create_namespace
      command << '--wait' if @config.wait
      command << atomic_flag if @config.atomic
      command.push('--timeout', @config.timeout) if Kubeconfig.present?(@config.timeout)
      command
    end

    def append_values_and_set(command)
      @config.values.each { |value| command.push('--values', root_path(value)) }
      @config.set.each { |key, value| command.push('--set', "#{key}=#{value}") }
      command
    end

    # helm 4 deprecated --atomic in favour of --rollback-on-failure. Pick the
    # flag matching the installed helm; fall back to --atomic when the version
    # can't be determined (correct for helm 3, still accepted — with a
    # deprecation notice — on helm 4).
    def atomic_flag
      helm_major >= 4 ? '--rollback-on-failure' : '--atomic'
    end

    def helm_major
      out, _err, status = Open3.capture3(@config.helm, 'version', '--short')
      return 3 unless status.success?

      match = out.strip.match(/v?(\d+)\./)
      match ? match[1].to_i : 3
    rescue StandardError
      3
    end

    def append_cluster_options(command)
      global = @machine.config.k8s
      kubeconfig = Kubeconfig.resolve_path(@machine, global.kubeconfig)
      command.push('--kubeconfig', kubeconfig) if kubeconfig
      command.push('--kube-context', global.context) if Kubeconfig.present?(global.context)
      command
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'pathname'
require 'vagrant-k8s/kubeconfig'

RSpec.describe VagrantK8s::Kubeconfig do
  let(:root) { Pathname.new('/project') }

  def make_machine(kubectl: 'kubectl', kubeconfig: nil, context: nil, namespace: nil)
    config = Struct.new(:kubectl, :kubeconfig, :context, :namespace).new(kubectl, kubeconfig, context, namespace)
    Struct.new(:config, :env).new(
      Struct.new(:k8s).new(config),
      Struct.new(:root_path).new(root)
    )
  end

  it 'builds a full kubectl command with all options set' do
    machine = make_machine(kubeconfig: 'config/kube.yaml', context: 'kind-dev', namespace: 'apps')
    expected = ['kubectl', '--kubeconfig', File.expand_path('config/kube.yaml', root.to_s),
                '--context', 'kind-dev', '--namespace', 'apps', 'get', 'pods']
    expect(described_class.kubectl_command(machine, %w[get pods])).to eq(expected)
  end

  it 'omits --kubeconfig when kubeconfig is nil' do
    machine = make_machine(context: 'kind-dev')
    cmd = described_class.kubectl_command(machine, %w[get pods])
    expect(cmd).not_to include('--kubeconfig')
    expect(cmd).to include('--context', 'kind-dev')
  end

  it 'omits --context when context is nil' do
    machine = make_machine
    cmd = described_class.kubectl_command(machine, %w[get pods])
    expect(cmd).not_to include('--context')
  end

  it 'omits --namespace when namespace is nil' do
    machine = make_machine
    cmd = described_class.kubectl_command(machine, %w[get pods])
    expect(cmd).not_to include('--namespace')
  end

  it 'uses an absolute kubeconfig path as-is without expanding' do
    abs = File.expand_path('/abs/path/kube.yaml')
    machine = make_machine(kubeconfig: abs)
    cmd = described_class.kubectl_command(machine, %w[get pods])
    expect(cmd).to include('--kubeconfig', abs)
  end

  it 'expands a relative kubeconfig path from the project root' do
    machine = make_machine(kubeconfig: 'kubeconfigs/dev.yaml')
    expected = File.expand_path('kubeconfigs/dev.yaml', root.to_s)
    cmd = described_class.kubectl_command(machine, %w[get pods])
    expect(cmd).to include('--kubeconfig', expected)
  end

  it 'allows overriding context and namespace via keyword args' do
    machine = make_machine(context: 'default', namespace: 'default')
    cmd = described_class.kubectl_command(machine, %w[get pods], context: 'staging', namespace: 'staging-ns')
    expect(cmd).to include('--context', 'staging', '--namespace', 'staging-ns')
  end

  it 'respects a custom kubectl binary' do
    machine = make_machine(kubectl: '/usr/local/bin/kubectl')
    cmd = described_class.kubectl_command(machine, ['version'])
    expect(cmd.first).to eq('/usr/local/bin/kubectl')
  end
end

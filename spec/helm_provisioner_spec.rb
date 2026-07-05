# frozen_string_literal: true

require 'spec_helper'
require 'pathname'
require 'vagrant-k8s/kubeconfig'
require 'vagrant-k8s/command_runner'
require 'vagrant-k8s/provisioner'
require 'vagrant-k8s/helm_provisioner'

RSpec.describe VagrantK8s::HelmProvisioner do
  let(:k8s_config) { Struct.new(:kubectl, :kubeconfig, :context, :namespace).new('kubectl', nil, nil, nil) }
  let(:vm_config)  { Struct.new(:k8s).new(k8s_config) }
  let(:ui)         { double('ui', detail: nil, error: nil) }
  let(:root_path)  { Pathname.new('/project') }
  let(:env)        { double('env', root_path: root_path) }
  let(:machine)    { double('machine', config: vm_config, ui: ui, env: env) }

  def make_config(release: 'myapp', chart: 'myrepo/myapp', **attrs)
    cfg = VagrantK8s::HelmConfig.new
    cfg.release = release
    cfg.chart   = chart
    attrs.each { |k, v| cfg.public_send(:"#{k}=", v) }
    cfg.finalize!
    cfg
  end

  def provisioner(config)
    described_class.new(machine, config)
  end

  def fake_status(success)
    Struct.new(:success?, :exitstatus).new(success, success ? 0 : 1)
  end

  it 'builds a basic helm upgrade --install command' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config).provision
    expect(ran).to include('helm', 'upgrade', '--install', 'myapp', 'myrepo/myapp')
  end

  it 'includes --repo when repo is set' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(repo: 'https://charts.example.com')).provision
    expect(ran).to include('--repo', 'https://charts.example.com')
  end

  it 'includes --version when version is set' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(version: '1.2.3')).provision
    expect(ran).to include('--version', '1.2.3')
  end

  it 'includes --namespace when namespace is set on the config' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(namespace: 'staging')).provision
    expect(ran).to include('--namespace', 'staging')
  end

  it 'falls back to k8s.namespace when helm namespace is nil' do
    k8s_config.namespace = 'default-ns'
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config).provision
    expect(ran).to include('--namespace', 'default-ns')
  end

  it 'includes --wait when wait is true' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(wait: true)).provision
    expect(ran).to include('--wait')
  end

  it 'includes --atomic when atomic is true on helm 3' do
    allow(Open3).to receive(:capture3).and_return(["v3.14.0+gabc\n", '', fake_status(true)])
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(atomic: true)).provision
    expect(ran).to include('--atomic')
    expect(ran).not_to include('--rollback-on-failure')
  end

  it 'uses --rollback-on-failure instead of --atomic on helm 4' do
    allow(Open3).to receive(:capture3).and_return(["v4.2.2+gb05881c\n", '', fake_status(true)])
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(atomic: true)).provision
    expect(ran).to include('--rollback-on-failure')
    expect(ran).not_to include('--atomic')
  end

  it 'falls back to --atomic when the helm version cannot be determined' do
    allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(atomic: true)).provision
    expect(ran).to include('--atomic')
  end

  it 'expands --values paths relative to the project root' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(values: ['values/prod.yml'])).provision
    expected_path = File.expand_path('values/prod.yml', root_path.to_s)
    expect(ran).to include('--values', expected_path)
  end

  it 'includes --set for each key=value pair' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(set: { 'image.tag' => 'v2', 'replicas' => 3 })).provision
    expect(ran).to include('--set')
    joined = ran.join(' ')
    expect(joined).to include('image.tag=v2')
    expect(joined).to include('replicas=3')
  end

  it 'appends --kube-context from k8s.context' do
    k8s_config.context = 'kind-test'
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config).provision
    expect(ran).to include('--kube-context', 'kind-test')
  end

  it 'appends --kubeconfig from k8s.kubeconfig' do
    k8s_config.kubeconfig = '/abs/kubeconfig'
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config).provision
    expect(ran).to include('--kubeconfig')
  end

  describe 'HelmConfig#validate' do
    it 'requires release and chart' do
      cfg = VagrantK8s::HelmConfig.new
      cfg.finalize!
      errors = cfg.validate(nil)['vagrant-k8s']
      expect(errors).to include(include('release'), include('chart'))
    end
  end
end

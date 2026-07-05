# frozen_string_literal: true

require 'spec_helper'
require 'pathname'
require 'vagrant-k8s/kubeconfig'
require 'vagrant-k8s/command_runner'
require 'vagrant-k8s/provisioner'
require 'vagrant-k8s/kustomize_provisioner'

RSpec.describe VagrantK8s::KustomizeProvisioner do
  let(:k8s_config) { Struct.new(:kubectl, :kubeconfig, :context, :namespace).new('kubectl', nil, nil, nil) }
  let(:vm_config)  { Struct.new(:k8s).new(k8s_config) }
  let(:ui)         { double('ui', detail: nil, error: nil) }
  let(:root_path)  { Pathname.new('/project') }
  let(:env)        { double('env', root_path: root_path) }
  let(:machine)    { double('machine', config: vm_config, ui: ui, env: env) }

  def make_config(path: 'k8s/overlays/dev', **attrs)
    cfg = VagrantK8s::KustomizeConfig.new
    cfg.path = path
    attrs.each { |k, v| cfg.public_send(:"#{k}=", v) }
    cfg.finalize!
    cfg
  end

  def provisioner(config)
    described_class.new(machine, config)
  end

  it 'builds a kubectl apply -k command' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config).provision
    expected_path = File.expand_path('k8s/overlays/dev', root_path.to_s)
    expect(ran).to include('kubectl', 'apply', '-k', expected_path)
  end

  it 'includes --server-side when server_side is true' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(server_side: true)).provision
    expect(ran).to include('--server-side')
  end

  it 'includes --force-conflicts when force_conflicts is true' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(server_side: true, force_conflicts: true)).provision
    expect(ran).to include('--force-conflicts')
  end

  it 'includes --prune and --selector when prune is true' do
    ran = nil
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| ran = cmd }
    provisioner(make_config(prune: true, prune_selector: 'app=myapp')).provision
    expect(ran).to include('--prune', '--selector', 'app=myapp')
  end

  it 'runs an additional wait command when wait is true' do
    commands = []
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| commands << cmd }
    provisioner(make_config(wait: true)).provision
    wait_cmd = commands.find { |c| c.include?('wait') }
    expect(wait_cmd).to include('--for=condition=ready', 'pod', '--all')
  end

  it 'tolerates "no matching resources" on the wait command (pod-less kustomization)' do
    captured = {}
    allow(VagrantK8s::CommandRunner).to receive(:run) do |_ui, cmd, **kwargs|
      captured = kwargs if cmd.include?('wait')
    end
    provisioner(make_config(wait: true)).provision
    expect(captured[:tolerate]).to match('error: no matching resources found')
    expect(captured[:tolerate_message]).to match(/\S/)
  end

  it 'does not run a wait command when wait is false' do
    commands = []
    allow(VagrantK8s::CommandRunner).to receive(:run) { |_ui, cmd, **_| commands << cmd }
    provisioner(make_config).provision
    expect(commands.length).to eq(1)
  end

  describe 'KustomizeConfig#validate' do
    it 'requires path' do
      cfg = VagrantK8s::KustomizeConfig.new
      cfg.finalize!
      errors = cfg.validate(nil)['vagrant-k8s']
      expect(errors).to include(include('path'))
    end

    it 'requires prune_selector when prune is true' do
      cfg = VagrantK8s::KustomizeConfig.new
      cfg.path  = 'k8s/'
      cfg.prune = true
      cfg.finalize!
      errors = cfg.validate(nil)['vagrant-k8s']
      expect(errors).to include(include('prune_selector'))
    end
  end
end

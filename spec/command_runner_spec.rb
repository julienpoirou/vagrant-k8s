# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'vagrant-k8s/command_runner'

RSpec.describe VagrantK8s::CommandRunner do
  let(:ui) { spy('ui') } # rubocop:disable RSpec/VerifiedDoubles

  def fake_status(success)
    Struct.new(:success?, :exitstatus).new(success, success ? 0 : 1)
  end

  it 'returns stdout on success' do
    allow(Open3).to receive(:capture3).and_return(["hello\n", '', fake_status(true)])
    result = described_class.run(ui, %w[kubectl get pods])
    expect(result).to eq("hello\n")
  end

  it 'logs stdout via ui.detail' do
    allow(Open3).to receive(:capture3).and_return(['output', '', fake_status(true)])
    described_class.run(ui, %w[kubectl get pods])
    expect(ui).to have_received(:detail).with('output')
  end

  it 'logs stderr via ui.error when present' do
    allow(Open3).to receive(:capture3).and_return(['', 'something went wrong', fake_status(true)])
    described_class.run(ui, %w[kubectl get pods])
    expect(ui).to have_received(:error).with('something went wrong')
  end

  it 'skips stdout ui.detail when stdout is empty' do
    allow(Open3).to receive(:capture3).and_return(['', '', fake_status(true)])
    described_class.run(ui, %w[kubectl get pods])
    expect(ui).not_to have_received(:detail).with('')
  end

  it 'raises VagrantError when command exits with non-zero status' do
    allow(Open3).to receive(:capture3).and_return(['', 'error', fake_status(false)])
    expect { described_class.run(ui, %w[kubectl get pods]) }
      .to raise_error(Vagrant::Errors::VagrantError, /Command failed/)
  end

  it 'raises VagrantError when executable is not found' do
    allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
    expect { described_class.run(ui, %w[nonexistent-cmd]) }
      .to raise_error(Vagrant::Errors::VagrantError, /Executable not found/)
  end

  it 'tolerates a non-zero exit whose stderr matches the tolerate pattern' do
    allow(Open3).to receive(:capture3)
      .and_return(['', 'error: no matching resources found', fake_status(false)])
    result = described_class.run(ui, %w[kubectl wait pod --all], tolerate: /no matching resources found/i)
    expect(result).to eq('')
    expect(ui).not_to have_received(:error)
  end

  it 'logs tolerate_message instead of the raw stderr when tolerating' do
    allow(Open3).to receive(:capture3)
      .and_return(['', 'error: no matching resources found', fake_status(false)])
    described_class.run(ui, %w[kubectl wait pod --all],
                        tolerate: /no matching resources found/i, tolerate_message: 'Nothing to wait for.')
    expect(ui).to have_received(:detail).with('Nothing to wait for.')
    expect(ui).not_to have_received(:detail).with('error: no matching resources found')
    expect(ui).not_to have_received(:error)
  end

  it 'still raises when stderr does not match the tolerate pattern' do
    allow(Open3).to receive(:capture3).and_return(['', 'some other failure', fake_status(false)])
    expect { described_class.run(ui, %w[kubectl wait pod --all], tolerate: /no matching resources found/i) }
      .to raise_error(Vagrant::Errors::VagrantError, /Command failed/)
  end

  it 'passes chdir to Open3.capture3' do
    allow(Open3).to receive(:capture3).with(*%w[kubectl get pods], chdir: '/project')
                                      .and_return(['', '', fake_status(true)])
    described_class.run(ui, %w[kubectl get pods], chdir: '/project')
    expect(Open3).to have_received(:capture3).with(*%w[kubectl get pods], chdir: '/project')
  end
end

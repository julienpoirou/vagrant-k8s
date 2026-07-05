# frozen_string_literal: true

require 'spec_helper'
require 'vagrant-k8s/config'

RSpec.describe VagrantK8s::Config do
  subject(:config) { described_class.new }

  it 'uses kubectl defaults without forcing a kubeconfig' do
    config.finalize!

    expect(config.kubectl).to eq('kubectl')
    expect(config.kubeconfig).to be_nil
    expect(config.validate(nil).fetch('vagrant-k8s')).to be_empty
  end
end

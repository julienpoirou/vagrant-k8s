# frozen_string_literal: true

require_relative 'command_runner'
require_relative 'kubeconfig'

module VagrantK8s
  class BaseProvisioner < Vagrant.plugin('2', :provisioner)
    def initialize(machine, config)
      super
      @machine = machine
      @config = config
    end

    private

    def run(command, tolerate: nil, tolerate_message: nil)
      CommandRunner.run(@machine.ui, command, chdir: @machine.env.root_path.to_s,
                                              tolerate: tolerate, tolerate_message: tolerate_message)
    end

    def root_path(path)
      return path if Pathname.new(path).absolute?

      File.expand_path(path, @machine.env.root_path.to_s)
    end
  end
end

# frozen_string_literal: true

unless defined?(Vagrant)
  module Vagrant
    module Errors
      class VagrantError < StandardError; end
    end

    def self.plugin(_version, type = nil)
      return Class.new unless type

      case type
      when :config
        Class.new do
          const_set(:UNSET_VALUE, :__UNSET__)
        end
      when :provisioner
        Class.new do
          def initialize(machine, config)
            @machine = machine
            @config  = config
          end
        end
      else
        Class.new
      end
    end
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
end

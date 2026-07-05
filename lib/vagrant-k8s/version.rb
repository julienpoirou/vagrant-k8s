# frozen_string_literal: true

module VagrantK8s
  VERSION = File.read(File.join(__dir__, 'VERSION')).split('#').first.strip
end

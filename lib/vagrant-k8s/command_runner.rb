# frozen_string_literal: true

require 'open3'

module VagrantK8s
  module CommandRunner
    # Raised when a command exits non-zero. Subclasses VagrantError so callers
    # can still rescue it as one, but carries its own message: VagrantError drops
    # a positional message string and would otherwise display "No error message".
    class CommandError < Vagrant::Errors::VagrantError
      def initialize(message)
        @command_error_message = message
        super()
      end

      def to_s
        @command_error_message
      end

      def message
        @command_error_message
      end
    end

    module_function

    # tolerate: optional Regexp. When the command fails but its stderr matches it,
    # the failure is treated as a benign no-op (e.g. `kubectl wait` finding no
    # matching resources) — logged as detail instead of raising.
    # tolerate_message: friendly text to log in that case instead of echoing the
    # raw (and alarming) stderr.
    def run(ui, command, chdir: nil, tolerate: nil, tolerate_message: nil)
      ui.detail("Executing: #{command.join(' ')}")
      stdout, stderr, status = Open3.capture3(*command, chdir: chdir)
      ui.detail(stdout.rstrip) unless stdout.empty?

      if !status.success? && tolerate && stderr.match?(tolerate)
        note = tolerate_message || stderr.rstrip
        ui.detail(note) unless note.to_s.empty?
        return stdout
      end

      ui.error(stderr.rstrip) unless stderr.empty?
      raise CommandError, "Command failed (exit #{status.exitstatus}): #{command.first}" unless status.success?

      stdout
    rescue Errno::ENOENT
      raise CommandError, "Executable not found: #{command.first}"
    end
  end
end

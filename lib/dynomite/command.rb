require "thor"

# Override thor's long_desc identation behavior
# https://github.com/erikhuda/thor/issues/398
class Thor
  module Shell
    class Basic
      def print_wrapped(message, options = {})
        message = "\n#{message}" unless message[0] == "\n"
        stdout.puts message
      end
    end
  end
end

module Dynomite
  class Command < Thor
    class << self
      def dispatch(m, args, options, config)
        # Allow calling for help via:
        #   dynomite command help
        #   dynomite command -h
        #   dynomite command --help
        #   dynomite command -D
        #
        # as well thor's normal way:
        #
        #   dynomite help command
        help_flags = Thor::HELP_MAPPINGS + ["help"]
        if args.length > 1 && !(args & help_flags).empty?
          args -= help_flags
          args.insert(-2, "help")
        end

        #   dynomite version
        #   dynomite --version
        #   dynomite -v
        version_flags = ["--version", "-v"]
        if args.length == 1 && !(args & version_flags).empty?
          args = ["version"]
        end

        super
      end

      # Override command_help to include the description at the top of the
      # long_description.
      def command_help(shell, command_name)
        meth = normalize_command_name(command_name)
        command = all_commands[meth]
        alter_command_description(command)
        super
      end

      def alter_command_description(command)
        return unless command

        # Add description to beginning of long_description
        long_desc = if command.long_description
            "#{command.description}\n\n#{command.long_description}"
          else
            command.description
          end

        # add reference url to end of the long_description
        unless website.empty?
          full_command = [command.ancestor_name, command.name].compact.join('-')
          url = "#{website}/reference/dynomite-#{full_command}"
          long_desc += "\n\nHelp also available at: #{url}"
        end

        command.long_description = long_desc
      end
      private :alter_command_description

      # meant to be overriden
      def website
        ""
      end

      # https://github.com/erikhuda/thor/issues/244
      # Deprecation warning: Thor exit with status 0 on errors. To keep this behavior, you must define `exit_on_failure?` in `Lono::CLI`
      # You can silence deprecations warning by setting the environment variable THOR_SILENCE_DEPRECATION.
      def exit_on_failure?
        true
      end
    end
  end
end

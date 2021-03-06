require 'optparse'
require_relative 'base'

module VagrantPlugins
  module Invade
    module Command
      class Build < Base
        def execute
          options = {}
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant invade build [-f|--force] [-q|--quiet] [-h]"
            o.separator ""
            o.on("-f", "--force", "Overwrite existing Vagrantfile") do |f|
              options[:force] = f
            end
            o.on("-q", "--quiet", "No verbose output.") do |q|
              options[:quiet] = q
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          # Validates InVaDE configuration
          action(Action.build, {
            :invade_build_force => options[:force],
            :invade_build_quiet => options[:quiet],
            :invade_validate_quiet => true # set this to true. Just build without validate output
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end

module VagrantPlugins
  module Invade
    module Action

      include Vagrant::Action::Builtin

      class Validate

        def initialize(app, env)
          @app = app
          @env = env
          @logger = Log4r::Logger.new('vagrant::invade::action::validate')
        end

        def call(env)
          config = env[:invade]
          quiet = @env[:invade_validate_quiet]

          Validator.set_env(@env)

          ###############################################################
          # Validate the settings and set default variables if needed
          ###############################################################

          # INVADE
          config['invade'] = Validator::Invade.new(config['invade']).validate

          # Hostmanager Plugin
          unless config['hostmanager'] == nil
            config['hostmanager'] = Validator::HostManager.new( config['hostmanager']).validate
          end

          # Iterate over each machine configuration
          machines = config['machines']
          unless machines == nil
            machines.each_with_index do |(machine, sections), index|

              # VM
              unless sections['vm'] == nil
                @env[:ui].info("\n[Invade] #{machine.upcase}: Validating VM section...") unless quiet
                sections['vm'] = Validator::VM.new(env, sections['vm']).validate
              end

              # NETWORK
              unless sections['network'] == nil
                @env[:ui].info("\n[Invade] #{machine.upcase}: Validating NETWORK section...") unless quiet

                sections['network'].each do |type, network|
                  @env[:ui].info("\tNetwork: #{type}") unless quiet
                  case type
                  when 'private', 'private_network', 'privatenetwork', 'private-network'
                    network = Validator::Network::PrivateNetwork.new(env, network).validate
                  when 'forwarded', 'forwarded_port', 'forwarded-port', 'forwardedport', 'port'
                    network = Validator::Network::ForwardedPort.new(@machine_name, network).validate
                  when 'public', 'puplic_network', 'publicnetwork', 'public-network'
                    network = Validator::Network::PublicNetwork.new(@machine_name, network).validate
                  else
                    raise StandardError, "Network type unknown or not set. Please check network section in configuration."
                  end
                end
              end

              # PROVIDER
              unless sections['provider'] == nil
                @env[:ui].info("\n[Invade] #{machine.upcase}: Validating PROVIDER section...") unless quiet

                sections['provider'].each do |type, provider|
                  @env[:ui].info("    Provider: #{type}") unless quiet
                  case type
                  when 'virtualbox'
                    provider = Validator::Provider::VirtualBox.new(env, provider).validate
                  when 'vmware'
                    provider = Validator::Provider::VMware.new(env, provider).validate
                  else
                    raise StandardError, "Provider unknown or not set. Please check provider section in configuration."
                  end
                end
              end

              # SYNCED FOLDER
              unless sections['synced_folder'] == nil
                @env[:ui].info("\n[Invade] #{machine.upcase}: Validating SYNCED FOLDER section...") unless quiet

                sections['synced_folder'].each do |name, sf|
                  @env[:ui].info("    Synced Folder: #{name}") unless quiet
                  case sf['type']
                  when 'nfs'
                    sf = Validator::SyncedFolder::NFS.new(env, sf).validate
                  when 'vb'
                    sf = Validator::SyncedFolder::VB.new(env, sf).validate
                  else
                    raise StandardError, "Synced Folder type unknown or not set. Please check synced folder section in configuration."
                  end
                end
              end

              # PROVISION
              unless sections['provision'] == nil
                @env[:ui].info("\n[Invade] #{machine.upcase}: Validating PROVISION section...") unless quiet

                sections['provision'].each do |name, provision|
                  @env[:ui].info("    Provision: #{name}") unless quiet
                  case provision['type']
                  when 'shell'
                    provision = Validator::Provision::Shell.new(env, provision).validate
                  when 'shellinline', 'shell-inline'
                    provision = Validator::Provision::ShellInline.new(env, provision).validate
                  when 'puppet', 'puppetapply', 'puppet-apply'
                    provision = Validator::Provision::PuppetApply.new(env, provision).validate
                  when 'puppet-agent', 'puppetagent', 'puppet-server', 'puppet-master'
                    provision = Validator::Provision::PuppetAgent.new(env, provision).validate
                  else
                    raise StandardError, "Provision type unknown or not set. Please check provision section in configuration."
                  end
                end
              end

              # SSH
              unless sections['ssh'] == nil
                @env[:ui].info("\n[Invade] #{machine.upcase}: Validating SSH section...") unless quiet

                sections['ssh'] = Validator::SSH.new(env, sections['ssh']).validate
              end

              # PLUGINS
              unless sections['plugin'] == nil
                @env[:ui].info("\n[Invade] #{machine.upcase}: Validating PLUGIN section...") unless quiet

                sections['plugin'].each do |type, plugin|
                  @env[:ui].info("    Plugin: #{type}") unless quiet
                  case type
                  when 'hostmanager'
                    plugin = Validator::Plugin::HostManager.new(env, plugin).validate
                  when 'winnfsd'
                    plugin = Validator::Plugin::WinNFSd.new(env, plugin).validate
                  when 'r10k'
                    plugin = Validator::Plugin::R10k.new(env, plugin).validate
                  else
                    raise StandardError, "Plugin type unknown or not set. Please check plugin section in configuration."
                  end
                end
              end

            end
          end

          if Validator.get_validation_errors > 0
            @env[:ui].warn('[Invade] Configuration has validation errors. Run \'vagrant invade validate\' to see details.')
            exit
          else
            @env[:ui].success('[Invade] Configuration validated successfully.')
          end

          @app.call(env)
        end

      end
    end
  end
end

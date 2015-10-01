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

          @config = env[:invade]

          Validator.set_env(@env)
          Validator.set_invade(@env)

          ###############################################################
          # Validate the settings and set default variables if needed
          ###############################################################

          # INVADE
          @config['invade'] = Validator::Invade.new(env, @config['invade']).validate

          # Iterate over each machine configuration
          machines = @config['machines']
          unless machines == nil
            machines.each_with_index do |(machine, sections), index|

              # BOX
              sections['box'] = Validator::Box.new(env, sections['box']).validate

              # NETWORK
              sections['network'] = Validator::Network.new(env, sections['network'], index).validate

              # PROVIDER
              unless sections['provider'] == nil
                sections['provider'].each do |type, provider|

                  case type
                  when 'virtualbox'
                    provider = Validator::Provider::VirtualBox.new(env, provider).validate
                  when 'vmware'
                    provider = Validator::Provider::VMware.new(env, provider).validate
                  else
                    raise StandardError, "Provider unknown or not set. Please check configuration file."
                  end

                  section = provider
                end
              end

              # SYNCED FOLDER
              unless sections['synced_folder'] == nil
                sections['synced_folder'].each do |type, sf|

                  case type
                  when 'nfs'
                    sf = Validator::SyncedFolder::NFS.new(env, sf).validate
                  when 'vb'
                    sf = Validator::SyncedFolder::VB.new(env, sf).validate
                  else
                    raise StandardError, "Synced Folder type unknown or not set. Please check configuration file."
                  end

                  section = sf
                end
              end

              # PROVISION
              unless sections['provision'] == nil
                sections['provision'].each do |type, provision|

                  case type
                  when 'shell'
                    provision = Validator::Provision::Shell.new(env, provision).validate
                  when 'puppet'
                    provision = Validator::Provision::Puppet.new(env, provision).validate
                  else
                    raise StandardError, "Provision type unknown or not set. Please check configuration file."
                  end

                  section = provision
                end
              end

              # SSH
              unless sections['ssh'] == nil
                sections['ssh'] = Validator::SSH.new(env, sections['ssh']).validate
              end

              # # PLUGINS
              # @env[:ui].info("[Invade] Validate machine #{machine.upcase} - Plugins") if @config['debug']
              #
              # # PLUGIN: Hostmanager
              # @env[:ui].info("\tHostmanager:") if @config['debug']
              # sections['plugins']['hostmanager']['enabled'] = validate(
              #   sections['plugins']['hostmanager']['enabled'], 'enabled', 'bool', true
              # )
              # sections['plugins']['hostmanager']['manage_host'] = validate(
              #   sections['plugins']['hostmanager']['manage_host'], 'manage_host', 'bool', true
              # )
              # sections['plugins']['hostmanager']['ignore_private_ip'] = validate(
              #   sections['plugins']['hostmanager']['ignore_private_ip'], 'ignore_private_ip', 'bool', false
              # )
              # sections['plugins']['hostmanager']['include_offline'] = validate(
              #   sections['plugins']['hostmanager']['include_offline'], 'include_offline', 'bool', true
              # )
              # sections['plugins']['hostmanager']['aliases'] = validate(
              #   sections['plugins']['hostmanager']['aliases'], 'aliases', 'array', []
              # )
              #
              # # PLUGIN: Winnfsd
              # @env[:ui].info("\tWinnfsd:") if @config['debug']
              # sections['plugins']['winnfsd']['enabled'] = validate(
              #   sections['plugins']['winnfsd']['enabled'], 'enabled', 'bool', true
              # )
              # sections['plugins']['winnfsd']['logging'] = validate(
              #   sections['plugins']['winnfsd']['logging'], 'logging', 'bool', false
              # )
            end
          end

          if Validator::VALIDATION_ERRORS > 0
            @env[:ui].warn('[Invade] Validation of configuration has warnings. Use debug mode to see details.')
          else
            @env[:ui].success('[Invade] Validation of configuration succeeded.')
          end

          @app.call(env)
        end

      end
    end
  end
end

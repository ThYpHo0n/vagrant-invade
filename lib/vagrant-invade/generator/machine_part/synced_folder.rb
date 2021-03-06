module VagrantPlugins
  module Invade
    module Generator
      module MachinePart

        class SyncedFolder

          attr_accessor :machine_name, :synced_folder_data

          def initialize(machine_name, synced_folder_data)
            @machine_name = machine_name
            @synced_folder_data = synced_folder_data
          end

          def generate
            case @synced_folder_data['type']
            when 'vb', 'virtualbox'
              synced_folder = Builder::SyncedFolder::VirtualBox.new(@machine_name, @synced_folder_data)
            when 'nfs'
              synced_folder = Builder::SyncedFolder::NFS.new(@machine_name, @synced_folder_data)
            else
              raise StandardError, "Synced folder type unknown or not set. Please check the synced folder configuration."
            end

            synced_folder.build

            synced_folder.result
          end

        end

      end
    end
  end
end

require 'active_support/core_ext/string/inflections'
require_relative 'cli'
require_relative 'comparer'
require_relative 'providers/aws'
require_relative 'providers/oci'
require_relative 'kube/client'
require_relative 'utils/log'

module VolumeSweeper
  module Core
    def self.process
      # Process user input ..
      opts = VolumeSweeper::Cli.run
      cloud = opts.cloud
      options = {
        config_path: opts.config_path,
        account_id: opts.account_id,
        region: opts.region,
        mode: opts.mode,
        kube_api_url: opts.kube_api_url,
        kube_api_ca_path: opts.kube_api_ca_path,
        kube_api_token: opts.kube_api_token
      }

      unless cloud.nil? || %w{oci aws}.include?(cloud)
        Utils::Log.instance.msg "No could provider is chosen", level: :fatal
        exit
      end

      # Build and run provider checks ..
      klass = cloud.capitalize
      provider = "VolumeSweeper::Providers::#{klass}".constantize.new **options
      block_vols = provider.scan_block_volumes.map { |v| v[:id] }

      # Build and run kubernetes checks ..
      kube_client = VolumeSweeper::Kube::Client.new **options
      cluster_vols = kube_client.fetch_pesistent_volumes

      # Run cross reference checks.
      results = Comparer.process block_vols, cluster_vols
      # Then, clean up any unattached block volume without PV bound to.
      provider.delete_block_volumes results[:unused_ids]

      VolumeSweeper::Utils::Log.instance.msg "Done !"
    end
  end
end

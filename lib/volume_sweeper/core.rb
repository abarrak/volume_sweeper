require 'active_support/core_ext/string/inflections'
require_relative 'cli'
require_relative 'comparer'
require_relative 'providers/aws'
require_relative 'providers/oci'
require_relative 'kube/client'
require_relative 'utils/log'
require_relative 'utils/notification'
require_relative 'utils/notification_formatter'

module VolumeSweeper
  module Core
    def self.process
      # Process user input ..
      opts = VolumeSweeper::Cli.run
      cloud = opts.cloud
      mode = opts.mode&.to_sym
      options = {
        config_path: opts.config_path,
        account_id: opts.account_id,
        region: opts.region,
        mode: opts.mode,
        kube_api_url: opts.kube_api_url,
        kube_api_ca_path: opts.kube_api_ca_path,
        kube_api_token: opts.kube_api_token,
        notification_subject: opts.notification_subject,
        smtp_host: opts.smtp_host,
        smtp_port: opts.smtp_port,
        smtp_username: opts.smtp_username,
        smtp_password: opts.smtp_password,
        smtp_tls: opts.smtp_tls,
        smtp_sender: opts.smtp_sender,
        smtp_receiver: opts.smtp_receiver,
        ms_teams_webhook: opts.ms_teams_webhook
      }

      unless cloud.nil? || %w{oci aws}.include?(cloud)
        Utils::Log.instance.msg "No could provider is chosen", level: :fatal
        exit
      end

      # Build and run provider checks ..
      klass = cloud.capitalize
      provider = "VolumeSweeper::Providers::#{klass}".constantize.new **options
      active_count, block_vols = provider.scan_block_volumes
      block_vols.map! { |v| v[:id] }

      # Build and run kubernetes checks ..
      kube_client = VolumeSweeper::Kube::Client.new **options
      cluster_vols = kube_client.fetch_pesistent_volumes

      # Prepare notification layer ..
      notifier  = VolumeSweeper::Utils::Notification.new **options
      formatter = VolumeSweeper::Utils::NotificationFormatter.new provider.base_link, mode

      # Run cross reference checks.
      results = Comparer.process block_vols, cluster_vols

      # Send notice messages.
      message = formatter.formlate_meessage results, active_count: active_count
      notifier.send_ms_teams_notice message
      notifier.send_mail message if results[:unused_ids]&.any?

      # Then, clean up any unattached block volume without PV bound to.
      provider.delete_block_volumes results[:unused_ids]

      # Wait for plaform logs aggregation.
      sleep 30

      VolumeSweeper::Utils::Log.instance.msg "Done !"
    end
  end
end

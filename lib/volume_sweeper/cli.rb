require 'optparse'
require 'ostruct'
require 'cowsay'
require_relative 'utils/log'

module VolumeSweeper
  class Cli
    class << self
      attr_reader :options
      ##
      # A simple cli scriptlet to proccess command line arguments and pass them to
      # the core component to run.
      #
      def run
        print_banner
        set_default_options
        process_user_input
        options
      end

      private

      def print_banner
        puts Cowsay::say('Volume Sweeper 1.0', 'cow'), ""
      end

      def process_user_input
        OptionParser.new("== Usage: volume_sweeper.rb [options]") do |opt|
          opt.on('-m', '--mode [MODE]', 'The run modes: either audit, or delete.') { |o| options.mode = o }
          opt.on('-c', '--cloud [CLOUD]', 'Supported clouds: aws, oci.') { |o| options.cloud = o }
          opt.on('-f', '--config-path [PATH]', 'The file location for cloud config file') { |o| options.config_path = o }
          opt.on('-s', '--creds-path [PATH]', 'The file location for cloud crednetials file') { |o| options.creds_path = o }
          opt.on('-r', '--region [REGION]', 'The provider region of the account.') { |o| options.region = o }
          opt.on('-a', '--account-id [Id]', 'The account or compartment Id.') { |o| options.account_id = o }
          opt.on('-d', '--released-since [DAYS]', 'Volumes threshold duration') { |o| options.released_in_days = o }
          opt.on('--kube-api-url [URL]', 'Kubernetes API URL') { |o| options.kube_api_url = o }
          opt.on('--kube-api-ca-path [PATH]', 'Kubernetes API CA Cert Path') { |o| options.kube_api_ca_path = o }
          opt.on('--kube-api-token [TOKEN]', 'Kubernetes API TOKEN (base64 formatted)') { |o| options.kube_api_token = o }
          opt.on('--notification_subject [TEXT]', 'The message subject.') { |o| options.notification_subject = o }
          opt.on('--smtp-host [HOST]', '') { |o| options.smtp_host = o }
          opt.on('--smtp-port [PORT]', '') { |o| options.smtp_port = o }
          opt.on('--smtp-username [USER]', '') { |o| options.smtp_username = o }
          opt.on('--smtp-password [PASS]', '') { |o| options.smtp_password = o }
          opt.on('--smtp-tls [ENABLE_TLS_FLAG]', '') { |o| options.smtp_tls = o }
          opt.on('--smtp-sender [SENDER]', '') { |o| options.smtp_sender = o }
          opt.on('--smtp-receiver [RECEIVER]', '') { |o| options.smtp_receiver = o }
          opt.on('--ms-teams-webhook [URL]', '') { |o| options.ms_teams_webhook = o }
          opt.on('-h', '--help') { |_| puts "", opt, "-" * 34; exit 0 }
        end.parse!
      end

      def set_default_options
        @options = OpenStruct.new
      end
    end

  end
end

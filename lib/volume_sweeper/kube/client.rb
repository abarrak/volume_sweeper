require "active_support/core_ext/object/blank"
require "base64"
require "kubeclient"
require_relative "../utils/log"

module VolumeSweeper
  module Kube
    ##
    #
    # This class enables interation with the kube apis using 2 different modes.
    #
    #   1. In-cluster acccess.
    #        Assuming the code will run in the cluster it targets,
    #        So the main defaults that pods that mount from service account
    #        secret like `token` and `ca.cert` are used in this case.
    #
    #   2. External cluster access.
    #       Pass the environment variables below to access outside cluster
    #         * KUBE_API_URL
    #         * KUBE_API_TOKEN
    #         * KUBE_API_CA_PATH
    #       Or their kwargs counterpart to constructor.
    #         * :kube_api_url
    #         * :kube_api_token [base64 formatted]
    #         * :kube_api_ca_path
    #
    #   The env vars take the highest precedence.
    #
    class Client
      def initialize **kwargs
        @run_mode = kwargs[:mode] || :audit
        @api_url = kwargs[:kube_api_url]
        @api_token = kwargs[:kube_api_token]
        @api_ca_path = kwargs[:kube_api_ca_path]

        @log = Utils::Log.instance
        prepare_kube_client
      end

      def fetch_pesistent_volumes
        resources = []
        make_api_call :get_persistent_volumes do |i|
          resources << format_response_attrs(i)
        end
        @log.msg "kube: Collected #{resources.size} persisted volumes from the cluster."

        resources
      end

      def delete_released_persistent_volumes age_in_days: 10
        names = []
        make_api_call :get_persistent_volumes do |i|
          names << i[:metadat][:name] if i.dig(:status, :phase) == "Released"
        end
        @log.msg "kube: Collected #{resources.size} released persisted volumes."

        return if names.blank? || @run_mode != :delete

        # Do actual deletion for released persistent volumes.
        # TODO: use last transistion timestamp if possible.
        @log.msg "kube: Looping over #{names.size} persisted volumes to be deleted sequentially."
        names.each do |pv|
          @log.msg "kube: deleting #{names} persisted volume .."
          @client.delete_pesistent_volume pv
          sleep 2
        end
        @log.msg "kube: completed deletion of #{names.size} persisted volume."
      end

      protected

      def prepare_kube_client
        url = "#{build_cluster_url}/api"
        @client ||= Kubeclient::Client.new url, "v1",
                                           auth_options: build_auth_config,
                                           ssl_options: build_ssl_config
        @log.msg "Kube: running in :#{@run_mode} mode"
      end

      def build_cluster_url
        default_cluster_url = "https://kubernetes.default.svc"
        ENV.fetch("KUBE_API_URL", @api_url || default_cluster_url)
      end

      def build_ssl_config
        default_ca_path = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        cluster_ca_path = ENV.fetch("KUBE_API_CA_PATH", @api_ca_path || default_ca_path)

        Hash.new.tap do |h|
          if File.exist? cluster_ca_path
            h[:ca_file] = cluster_ca_path
          else
            h[:verify_ssl] = OpenSSL::SSL::VERIFY_NONE
          end
        end
      end

      def build_auth_config
        cluster_token = ENV["KUBE_API_SECRET"]
        default_token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        Hash.new.tap do |h|
          if cluster_token.present?
            h[:bearer_token] = Base64.decode64 cluster_token
          elsif @api_token.present?
            h[:bearer_token] = Base64.decode64 @api_token
          elsif File.exist? default_token_path
            h[:bearer_token] = File.read default_token_path
          end
        end
      end

      def make_api_call method, **opts
        continue = nil
        { limit: 30 }.merge! opts
        loop do
          opts[:continue] = continue
          output = @client.send method, **opts
          continue = output.continue
          output.map(&:to_h).collect do |i|
            yield i
          end
          break if output.last?
        end
      end

      def format_response_attrs item
        {
          name: item.dig(:metadat, :name),
          status: item.dig(:status, :phase),
          volumeHandle: item.dig(:spec, :csi, :volumeHandle),
          pvc: item.dig(:spec, :claimRef, :name),
          namespace: item.dig(:spec, :claimRef, :namespace)
        }
      end
    end

  end
end

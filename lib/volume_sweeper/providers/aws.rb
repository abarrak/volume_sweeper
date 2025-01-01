require 'active_support/core_ext/object/blank'
require 'aws-sdk-ec2'
require_relative 'base'
require_relative '../utils/log'

module VolumeSweeper
  module Providers

    class Aws < Base

      DEFAULT_REGION = 'us-west-2'
      DEFAULT_CONFIF_PATH = '~/.aws/config'
      DEFAULT_CREDS_PATH  = '~/.aws/credentials'

      BASE_CONSOLE_URL = "console.aws.amazon.com/ec2/home"
      VOLUME_ATTRS = %i{ volume_id displayName state size attachments create_time availability_zone tags }

      def initialize config_path: nil, region: nil, mode: :audit, **kwargs
        super
        @region ||= DEFAULT_REGION
        set_console_base_url
        validate_attrs
        prepare_config config_path, kwargs[:creds_path]
      end

      def scan_block_volumes
        volumes = Array.new
        next_token = nil
        opts = { max_results: 200 }

        run_api_call do |client|
          loop do
            response = client.describe_volumes opts.merge(next_token: next_token)
            response&.volumes&.map do |v|
              volumes << v.to_hash.compact.slice(*VOLUME_ATTRS).transform_keys(volume_id: :id)
            end
            break if response.nil? || response.next_token.nil?
            next_token = response.next_token
            sleep 2
          end
          @log.msg "aws: collected #{volumes.size} block volumes from the account."
        end

        @log.msg "aws: filtering out any block volume with an active attachment."
        result = volumes&.reject { |v| v[:state] != 'available' || v[:attachments]&.count > 0 } || []

        @log.msg "aws: found #{result.count} unattached block volumes."
        [volumes.size, result]
      end

      def delete_block_volumes ids_list
        @log.msg "aws: #{ids_list&.count || 0} block volumes are eligible for cleanup."
        return if ids_list.blank?

        unless @run_mode == :delete
          @log.msg "aws: running in :#{@run_mode} mode, exiting without delete operations."
          return
        end

        @log.msg "aws: unused volume clean-up operation started."

        ids_list.each do |id|
          @log.msg "aws: deleting block volume #{id} .."
          run_api_call do |client|
            output = client.delete_volume({ volume_id: id.to_s })
            if output&.successful?
              @log.msg "aws: block volume #{id} is deleted successfully."
            else
              @log.msg "aws: block volume #{id} has failed."
            end
            sleep 2.5
          end
        end
      end

      private

      def prepare_config config_path, creds_path
        # SDK automtically picks up config and credentails files in the
        # default place for various methods.
        @config_location ||= DEFAULT_CONFIF_PATH
        @creds_location  ||= DEFAULT_CREDS_PATH
        ::Aws.config.update({ region: @region })
      end

      def validate_attrs
        return unless @account_id.blank?
        @log.msg "provider error: aws account id is not assigned", level: :error
        exit 1
      end

      def run_api_call
        current_tries = 0
        ec2_client = ::Aws::EC2::Client.new(region: @region, account_id: @account_id)

        yield ec2_client if block_given?

      rescue ::Aws::EC2::Errors::ServiceError => err
        # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/EBS/Errors.html
        @log.msg errr&.context&.data, level: :error
        raise if err&.code.to_s != '304'
      rescue StandardError => err
        @log.msg err, level: :error
        raise
      end

      def set_console_base_url
        @base_link = "https://#{@region}.#{BASE_CONSOLE_URL}?region=#{@region}#VolumeDetails:volumeId="
      end
    end

  end
end

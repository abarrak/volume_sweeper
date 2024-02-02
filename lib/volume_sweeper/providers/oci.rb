require 'oci/common'
require 'oci/auth/auth'
require 'oci/core/core'
require 'active_support/core_ext/object/blank'
require_relative 'base'
require_relative '../utils/log'

module VolumeSweeper
  module Providers

    class Oci < Base
      DEFAULT_REGION = 'me-jeddah-1'

      DEFAULT_PAGE_SIZE = 30
      VOLUME_ATTRS = %i{ id displayName volumeId lifecycleState sizeInGBs timeCreated definedTags freeformTags }

      attr_accessor :config_location

      def initialize config_path: nil, region: nil, mode: :audit, **kwargs
        super
        @region ||= DEFAULT_REGION
        validate_attrs
      end

      def scan_block_volumes
        volumes = Array.new
        opts = { compartment_id: @compartment_id, limit: DEFAULT_PAGE_SIZE }

        run_api_call do |config|
          api = OCI::Core::BlockstorageClient.new config: config, region: @region
          page = nil
          begin
            output = api.list_volumes **opts.merge({ page: page })
            page = output.headers['opc-next-page']
            output.data.map { |v| volumes << v.to_hash.compact.slice(*VOLUME_ATTRS) }
            sleep 2
          end until page.nil? || page&.empty?
          @log.msg "oci: collected #{volumes.size} block volumes from the compartment."
        end

        volume_attachments = Array.new
        opts = { limit: DEFAULT_PAGE_SIZE }
        run_api_call do |config|
          api = OCI::Core::ComputeClient.new config: config, region: @region
          page = nil
          begin
            output = api.list_volume_attachments @compartment_id, **opts.merge({ page: page })
            page = output.headers['opc-next-page']
            output.data.map do |v|
              volume_attachments << v.to_hash.compact.slice(*VOLUME_ATTRS) if v.lifecycle_state =~ /ATTACH/
            end
            sleep 2
          end until page.nil? || page&.empty?
          @log.msg "oci: collected #{volume_attachments.size} block volume attachements from the compartment."
        end

        @log.msg "oci: filtering out any block volume with an active attachment."
        result = volumes.reject do |v|
          volume_attachments.any? { |va| va[:volumeId] == v[:id] }
        end || []

        @log.msg "oci: found #{result.size} unattached block volumes."
        result
      end

      def delete_block_volumes ids_list
        @log.msg "oci: #{ids_list&.count || 0} block volumes are eligible for cleanup."
        return if ids_list.blank?

        unless @run_mode == :delete
          @log.msg "oci: running in :#{@run_mode} mode, exiting without delete operations."
          return
        end

        @log.msg "oci: unused volume clean-up operation started."

        ids_list.each do |id|
          @log.msg "oci: deleting block volume #{id} .."
          run_api_call do |config|
            api = OCI::Core::BlockstorageClient.new config: config, region: @region
            output = api.delete_volume id, compartment_id: @compartment_id
            if output.status.to_s =~ /2\d\d/
              @log.msg "oci: block volume #{id} is deleted successfully."
            else
              @log.msg "oci: block volume #{id} has failed."
            end
            sleep 2.5
          end
        end
      end

      private

      def prepare_config
        @config_location   ||= '~/.oci/config'
        @oci_configuration ||= OCI::ConfigFileLoader.load_config(
          config_file_location: self.config_location,
          profile_name: 'DEFAULT'
        )
      end

      def run_api_call
        prepare_config
        yield @oci_configuration if block_given?
      rescue OCI::Errors::ServiceError => err
        @log.msg err, level: :error
        raise if err.status_code != 304
      rescue OCI::Errors::NetworkError,
              OCI::Errors::ResponseParsingError,
              OCI::Errors
        @log.msg err, level: :error
        raise
      end

      def validate_attrs
        return unless @compartment_id.blank?
        @log.msg "provider error: oci compartment id is not assigned", level: :error
        exit 1
      end
    end

  end
end

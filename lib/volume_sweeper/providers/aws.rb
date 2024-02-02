require 'active_support/core_ext/object/blank'
require_relative 'base'
require_relative '../utils/log'

module VolumeSweeper
  module Providers

    class Aws < Base
      DEFAULT_REGION = 'us-west-2'

      def initialize config_path: nil, region: nil, mode: :audit, **kwargs
        super
        @region ||= DEFAULT_REGION
        validate_attrs
      end

      def scan_block_volumes
        raise NotImplementedError
      end

      def delete_block_volumes ids_list
        return if ids_list.blank? || @run_mode != :delete
        raise NotImplementedError
      end

      private

      def prepare_config
      end

      def validate_attrs
        return unless @account_id.blank?
        @log.msg "provider error: aws account id is not assigned", level: :error
        exit 1
      end
    end

  end
end

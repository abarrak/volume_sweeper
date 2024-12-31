module VolumeSweeper
  module Providers

    class Base
      attr_reader :base_link

      def initialize **kwargs
        @run_mode = kwargs[:mode]&.to_sym || :audit
        @config_location = kwargs[:config_path]
        @creds_location = kwargs[:creds_location]
        @account_id = kwargs[:account_id]
        @compartment_id = kwargs[:account_id]
        @region = kwargs[:region]

        @log = Utils::Log.instance
        @log.msg "#{self.class.name.downcase.split(":").last}: running in :#{@run_mode} mode."
      end

      def scan_volumes; end
      def delete_volumes ids_list; end
    end

  end
end

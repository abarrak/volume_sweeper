module VolumeSweeper
  module Providers

    class Base
      def initialize **kwargs
        @run_mode = kwargs[:mode] || :audit
        @config_location = kwargs[:config_path]
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

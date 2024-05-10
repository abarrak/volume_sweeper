require 'erb'
require 'active_support/core_ext/object/blank'

module VolumeSweeper
  module Utils
    class NotificationFormatter

      def initialize provider_base_url, run_mode
        @provider_base_url = provider_base_url
        @run_mode = run_mode || :audit
      end

      def formlate_meessage volumes, active_count: nil
        active_list = volumes[:active_ids]
        unused_list = volumes[:unused_ids]
        active_count = active_count || volumes[:active_ids] || 0

        if unused_list.blank? || unused_list.none?
          <<~EOD
            The environment is scanned and no unused block volumes found.<br>
            * Active volumes: #{active_count}<br>
            * Unused volumes: #{unused_list&.count || 0}<br>
          EOD
        else
          notice = @run_mode == :delete ? "scheduled for deletion!" : "eligibile for deletion."
          ERB.new(
            <<~HTML
              Found the following volumes with no instance bound or K8S PV relation.<br>
              <ul style="color: #400707">
                <% unused_list.each do |vol| %>
                <li>volume: <a href="#{@provider_base_url}/<%= vol %>"><%= vol %></a> is #{notice}.</li>
                <% end %>
              </ul>
            HTML
          ).result(binding)
        end
      end

    end
  end
end


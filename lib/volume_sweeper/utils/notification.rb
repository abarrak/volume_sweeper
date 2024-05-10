require 'mail'
require 'network-client'
require 'active_support/core_ext/object/blank'

module VolumeSweeper
  module Utils
    class Notification

      attr_reader :default_subject

      def initialize **kwargs
        @log = Utils::Log.instance

        setup_configuration **kwargs
        configure_mailer
        configure_ms_teams
      end

      def send_mail text
        return unless smtp_configured?
        @log.msg "#{self_name}: sending mail notification."

        sender, receiver = @smtp_sender, @smtp_receiver
        subject = message_subject
        content = build_message_content text
        Mail.deliver do
          from     sender
          to       receiver
          subject  subject
          content_type 'text/html; charset=UTF-8'
          body     content
        end

        @log.msg "#{self_name}: email is sent successfully.", level: :info

      rescue Exception => e
        @log.msg "#{self_name}: mail notification failed.", level: :error
        @log.msg "#{self_name}: #{e.message}.", level: :error
      end

      def send_ms_teams_notice text
        return unless @webhook_url.present?

        @log.msg "#{self_name}: sending ms teams notification."

        request = Net::HTTP::Post.new @webhook_url.request_uri
        request['Content-Type'] = 'application/json'
        request.body = { title: message_subject, text: text }.to_json

        http = Net::HTTP.new @webhook_url.host, @webhook_url.port
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        body = http.request(request)&.body
        @log.msg "#{self_name}: ms teams notification is sent."
        body
      rescue StandardError => e
        @log.msg "#{self_name}: ms teams notification failed.", level: :error
        @log.msg "#{self_name}: #{e.message}.", level: :error
      end

      private

      def self_name
        @klass ||= self.class.name.downcase.split(":").last
      end

      def setup_configuration **opts
        %i[smtp_host smtp_port smtp_username smtp_password notification_subject
           smtp_tls smtp_sender smtp_receiver ms_teams_webhook].each do |sym|
            @log.msg "#{self_name}: argument #{sym} is empty.", level: :warn if opts[sym].blank?
            instance_variable_set "@#{sym.to_s}", opts[sym]
        end
        default_subject = "Notification: block volume operation."
      end

      def smtp_configured?
        @smtp_host.present? && @smtp_port.present?
      end

      def configure_mailer
        return unless smtp_configured?

        host, port = @smtp_host, @smtp_port
        username = @smtp_username
        password = @smtp_password
        tls_flag = @smtp_tls&.downcase == 'true'
        auth = username.present? && password.present? ? 'login' : nil

        Mail.defaults do
          delivery_method :smtp, address: host, port: port, user_name: username,
                                 password: password, authentication: auth,
                                 enable_starttls_auto: tls_flag
        end
      end

      def configure_ms_teams
        return unless @ms_teams_webhook.present?
        @webhook_url = URI.parse @ms_teams_webhook
      end

      def message_subject
        @notification_subject || default_subject
      end

      def build_message_content text
        <<~EOD
          <style>
            body {
              background-color: whitesmoke;
              font-family: Georgia, Times;
              font-size: 15px;
            }
            .content {
              margin: 20px 20px 0 20px;
              padding: 10px;
              background-color: white;
            }
            .foot {
              margin: 0 20px 20px 20px;
              padding: 5px;
              border: 0;
              text-align: center;
              background-color: black;
              color: white;
              font-family: Arial, Times;
              font-size: 13px;
            }
          </style>
          <div class="content">
            Hello,
            <br><br>

            #{text}
            <br>

            Regards,<br>
            <span style="font-weight: 600">Automation</span>
            <br>
          </div>
          <div class="foot">
          © - Volume Sweeper Notification.
          </div>
        EOD
      end
    end
  end
end

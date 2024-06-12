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
              margin: 0 20px 0 20px;
              padding: 10px;
              background-color: white;
            }
            .header {
              margin: 20px 20px 0 20px;
              padding: 10px 10px 42px 10px;
              border: 0;
              text-align: right;
              background-color: rgb(226, 225, 225);
              color: rgb(69, 69, 69);
              font-family: Georgia, 'Times New Roman', Times, serif, Times;
              font-size: 16px;
            }
            .header p {
              text-align: right;
              margin: 0;
              margin-top: 6px;
              margin-right: 20px;
              float: right;
              display: block;
            }
            .header img {
              margin: 0;
              padding: 0;
              border: 0;
              float: left;
            }
            .foot {
              margin: 0 20px 20px 20px;
              padding: 5px;
              border: 0;
              text-align: center;
              text-align: left;
              background-color: black;
              color: white;
              font-family: Arial, Times;
              font-size: 13px;
            }
          </style>
          <div class="header">
            <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAAAeFBMVEX///8AAADl5eVdXV1jY2Pd3d2xsbH4+Pi2trbz8/Ph4eGampr8/PwwMDDw8PDMzMyJiYmrq6vGxsalpaWPj4+Dg4PV1dW9vb1XV1dAQEAQEBA3NzegoKBra2twcHDPz89RUVF6enofHx8+Pj4XFxd9fX0kJCRJSUmiWCO7AAAEmElEQVR4nO3c6XaqMBQFYIMoooBYwXmonXz/N7zVgGYg2isHEl37+wsrnq2IIYOdDgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAUTQe7fzdaBzZLqQhYcpKaWi7mCYMmGhguxx6KZOltguiNmKqke2SaO21gIztbRdF6qMi4YftoijNKwIyNrddFqFFZcKF7bLoBJUBGQtsF0ZmaEjo2S6MzJsh4dh2YWRMCd9sF0amZ0jYs10YmdCQ8IX635+VAZe2yyI0rUw4tV0Woagy4Us9CPcrAvZtF0XL1wL6tkui9q4EfLddEL2DFPBgu5wmbISAG9vFNEK827zYXaaAhM8PCZ8fEj4/JHx+SPj8Bi+SMEyGvUpDcYJtZDopcXx0an6IWV3xwdkZmzCrna6UOTmjUT2e9ij3xuECdZSirnfHPsZkRRyQsVViO5QoEQo7+nUchbfKpYiXO2haf7Kld1mXEhNURmRXlHSg+e4El/ZImiNQLiWhW+dUdn9cWZCy5uVQzncWc6prwiZrGPNqaIdAi8FVN+bBt+daPolb5RfGlrjVhwTNfGWKK8OF3/19Q3f22Jl7De+PZuTt8n68C/3Tw7kS+ieeuTM/iXzuc0jeLl9I5cI8avdcCf0CLu/cbpe83f+HhI9Cwva8fkK/0YR276VeP8vzNDYkHG/ybPKXH5HhJMs3et+FJ4zTPM/6dpbaetLibbWGcuRtObvTzGxZnKn2Xjyx+YWFjMo6LrmCYHk9crs/J4yxLuVetie/QOvzAOpCNTmhNPJ9K6I0iCz33pWEbUdUX15OeJCPmR9jx/KJUif09ks0TluIJ768ujTf/GSlznKINyYtYau31UR9dSmhuk2Nme42M/VEcUOblrDV8VN9l4+YcK0eNG1T0za0iUMhesI256T0vXZCQn1B8M7QzFY7U1g2rCdsc7mfPo8mJNT3AJm+QfqyWuEHQ09IP45gNrmVsPOlHswNzeTqieKGPT3hpMFEKu0WISXsqgdNg+Ha6m+xn60nvNc9IqV9TGJCrXDT3Ly200R8K7SEXw3m0WkTvtLPsTKZ+G1s5ls+cSUe0xK2eZH+WiovLyWUuyor876KSH4vpM6PmrDtHTbBz42E8kd8q7clxZiaDzH20/rodyTf6pUY1/14x9s9keR4OVOZu5ITbm1ssJnthB3a6gcVTU+lr/z7U25v/ulSPU7VCELCj12rt1FRGIbRwnQpBr8H/9RKFIYVlyBPuPg9aHuZ1OuPRCHho5CwPUj4KHcS8sdY+h8s/vziwlIF/jRM3y3mz6BtPvWa8PVL9ANhvFfowv9JFb0r6o5HWN0btCJu5HLiF78byxOLgTfa0cxiRNaNv8sqxtZoV9kVY64uLInqXMa4Kf8UqZi5c+VP3coh4DXVhZqUo+bO/K/EZVwmo7ijXvdtuLH28uw6yu9PZl4d+8l1dMSN20xBG70mYBopt0Sfq6nLqU/wZHy/5v/i0HewFGkTozWkztxFJcGo/t68k3jkyA99FW+Qbbt1bLOBE51tAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgGf2D4WAKMqRFhM1AAAAAElFTkSuQmCC" width="35px" height="35px">
            <p>< Maintenance Bot ></p>
          </div>
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

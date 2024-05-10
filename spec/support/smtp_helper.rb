##
# Mail Catcher spec hooks.
# extracted from:
# https://github.com/sj26/mailcatcher/blob/main/spec/spec_helper.rb
#
require "mail_catcher"

module Support
  module SmtpHelper
    extend self

    LOCALHOST = "127.0.0.1"
    SMTP_PORT = 20025
    HTTP_PORT = 20080

    def start_testing_server
      @pid = spawn "bundle", "exec", "mailcatcher", "--foreground",
                  "--smtp-port", SMTP_PORT.to_s, "--http-port", HTTP_PORT.to_s

      begin
        Socket.tcp(LOCALHOST, SMTP_PORT, connect_timeout: 1) { |s| s.close }
        Socket.tcp(LOCALHOST, HTTP_PORT, connect_timeout: 1) { |s| s.close }
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
        retry
      end
    end

    def close_testing_server
      sleep 1
      # Quit MailCatcher.
      Process.kill("TERM", @pid)
      Process.wait
      unless ENV['RACK_ENV'] == 'test'
        VolumeSweeper::Utils::Log.instance.msg "test server closed closed."
      end
    rescue Errno::ESRCH
      # It's already gone.
    end
  end
end

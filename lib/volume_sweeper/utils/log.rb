require 'logger'
require 'singleton'

module VolumeSweeper
  module Utils
    class Log
      include Singleton

      def initialize
        @logger = Logger.new STDOUT
        @logger.level = Logger::DEBUG
      end

      def msg *message, level: :info
        @logger.send level.to_s, message.join('').to_s if @logger.respond_to?(level)
      end
    end
  end
end

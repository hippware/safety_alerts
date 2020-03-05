# frozen_string_literal: true

require 'forwardable'
require 'logger'

module SafetyAlerts
  # Creates a singleton Logger to be used anywhere in the app.
  class Logger < ::Logger
    @logger = ::Logger.new(STDOUT)

    class << Logger
      attr_reader :logger

      def configure
        yield @logger
      end

      extend Forwardable

      delegate %i[debug info warn error fatal unknown] => :@logger
    end
  end
end

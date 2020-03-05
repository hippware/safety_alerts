# frozen_string_literal: true

require 'honeybadger/ruby'

require 'safety_alerts/db'
require 'safety_alerts/alert_importer'
require 'safety_alerts/geometry_importer'
require 'safety_alerts/secrets'
require 'safety_alerts/utils'

# This is the top-level namespace and entrypoint to the application.
module SafetyAlerts
  Secrets.configure

  Honeybadger.configure do |config|
    config.logging.path = 'STDOUT'
    config.logging.level = 'WARN'
    config.api_key = Secrets.get_value('honeybadger-api-key') || 'no-key'
    config.env = ENV['HONEYBADGER_ENV'] || 'development'
  end

  def self.run_alert_import(importer)
    AlertImporter.run(importer)
  end

  def self.run_geometry_import(importer)
    GeometryImporter.run(importer)
  end
end

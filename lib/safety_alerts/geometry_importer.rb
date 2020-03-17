# frozen_string_literal: true

module SafetyAlerts
  # This is the namespace for geometry importers, and provides the main
  # function that dynamically loads and executes geometry importers.
  module GeometryImporter
    def self.run(importer)
      source = importer.upcase

      require "safety_alerts/geometry_importer/#{source.downcase}"
      klass = const_get(importer.upcase)
      db = DB.new(source)

      count = klass.run(db)

      Logger.info { "Imported #{count} geometries from '#{source}'" }
    rescue StandardError => e
      Logger.fatal(e)
      Honeybadger.notify(e)
    end
  end
end

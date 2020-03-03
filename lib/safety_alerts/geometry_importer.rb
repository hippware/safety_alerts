# frozen_string_literal: true

module SafetyAlerts
  module GeometryImporter
    def self.run(importer)
      source = importer.upcase

      require "safety_alerts/geometry_importer/#{source.downcase}"
      klass = self.const_get(importer.upcase)
      db = DB.new(source)

      db.prepare_geometry_import

      count = klass.run(db)

      puts "Imported #{count} geometries from '#{source}'"
    rescue => error
      puts error

      Honeybadger.notify(error)
    ensure
      db&.close
    end
  end
end

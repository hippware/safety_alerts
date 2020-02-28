module SafetyAlerts
  module GeometryImporter
    def self.run(importer)
      require "safety_alerts/geometry_importer/#{importer.downcase}"

      klass = self.const_get(importer.upcase)

      count = klass.run

      puts "Imported #{count} geometries from '#{importer.upcase}'"
    end
  end
end

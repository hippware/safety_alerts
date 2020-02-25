module SafetyAlerts
  module Importer
    def self.run(importer)
      require "safety_alerts/importer/#{importer.downcase}"

      klass = self.const_get(importer.upcase)

      count = klass.run

      puts "Imported #{count} alerts from '#{importer.upcase}'"
    end
  end
end

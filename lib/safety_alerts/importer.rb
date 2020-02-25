module SafetyAlerts
  module Importer
    def self.run(importer)
      require "safety_alerts/importer/#{importer.downcase}"

      klass = self.const_get(importer.upcase)

      klass.run
    end
  end
end

require 'safety_alerts/alert_db'
require 'safety_alerts/importer'
require 'safety_alerts/secrets'
require 'safety_alerts/utils'

module SafetyAlerts
  def self.run_import(importer)
    SafetyAlerts::Importer.run(importer)
  end
end

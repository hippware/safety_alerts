require 'honeybadger'

require 'safety_alerts/db'
require 'safety_alerts/alert_importer'
require 'safety_alerts/geometry_importer'
require 'safety_alerts/secrets'
require 'safety_alerts/utils'

module SafetyAlerts
  def self.run_alert_import(importer)
    AlertImporter.run(importer)
  end

  def self.run_geometry_import(importer)
    GeometryImporter.run(importer)
  end
end

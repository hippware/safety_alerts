module SafetyAlerts
  module AlertImporter
    def self.run(importer)
      source = importer.upcase

      require "safety_alerts/alert_importer/#{source.downcase}"
      klass = self.const_get(source)
      db = DB.new(source)

      db.prepare_alert_import

      count = klass.run(db)

      db.delete_stale_alerts

      puts "Imported #{count} alerts from '#{source}'"
    rescue => error
      Honeybadger.notify(error)
    ensure
      db&.close
    end
  end
end

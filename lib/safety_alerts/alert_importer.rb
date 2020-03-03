# frozen_string_literal: true

module SafetyAlerts
  module AlertImporter
    def self.run(importer)
      source = importer.upcase

      require "safety_alerts/alert_importer/#{source.downcase}"
      klass = const_get(source)
      db = DB.new(source)

      db.prepare_alert_import

      count = klass.run(db)

      db.delete_stale_alerts

      puts "Imported #{count} alerts from '#{source}'"
    rescue StandardError => e
      puts e

      Honeybadger.notify(e)
    ensure
      db&.close
    end
  end
end

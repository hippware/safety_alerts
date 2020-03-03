# frozen_string_literal: true

require 'gull'
require 'json'

module SafetyAlerts
  module AlertImporter::US_NWS
    def self.run(db)
      count = 0

      Gull::Alert.fetch.each do |alert|
        ugcs =
          alert.geocode.ugc.split(' ').map do |code|
            code.sub(/([A-Z][A-Z])[CZ]([0-9]*)/, '\1\2')
          end

        geometry = db.get_geometry_union(ugcs)

        next unless geometry

        count += 1
        data = Utils.hashify(alert)
        data['geocode'] = Utils.hashify(alert.geocode)

        db.insert_alert(
          id: alert.id,
          expires_at: alert.expires_at,
          title: alert.title,
          summary: alert.summary,
          link: alert.link,
          geometry: geometry,
          data: data.to_json
        )
      end

      count
    end
  end
end

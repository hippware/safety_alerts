# frozen_string_literal: true

require 'gull'
require 'json'

module SafetyAlerts
  # Alert importer for the US National Weather Service.
  module AlertImporter::US_NWS
    def self.run(db)
      Gull::Alert.fetch.reduce(0) do |count, alert|
        ugcs = format_ugc_list(alert.geocode.ugc)
        geometry = db.get_geometry_union(ugcs)

        next count unless geometry

        db.insert_alert(
          id: alert.id,
          expires_at: alert.expires_at,
          title: alert.title,
          summary: alert.summary,
          link: alert.link,
          geometry: geometry,
          data: make_json(alert)
        )

        count + 1
      end
    end

    def self.format_ugc_list(ugc_string)
      ugc_string.split(' ').map do |code|
        code.sub(/([A-Z][A-Z])[CZ]([0-9]*)/, '\1\2')
      end
    end

    def self.make_json(alert)
      data = Utils.hashify(alert)
      data['geocode'] = Utils.hashify(alert.geocode)
      data.to_json
    end
  end
end

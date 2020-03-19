# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'net/http'
require 'rgeo/geo_json'

module SafetyAlerts
  # Alert importer for New Zealand's GeoNet earthquake service
  module AlertImporter::US_USGS
    def self.run(db)
      response =
          URI.open('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_day.geojson').read()

      collection = RGeo::GeoJSON.decode(response)

      collection.each do |f|
          description = "#{f.property('title')} at #{f.property('time')}"

        db.insert_alert(
          id: f.feature_id,
          expires_at: nil,
          title: "Magnitude #{f.property('mag')} Earthquake",
          summary: description,
          link: f.property('url'),
          geometry: f.geometry.as_text,
          data: JSON.dump(RGeo::GeoJSON.encode(f))
        )
      end

      collection.size
    end
  end
end

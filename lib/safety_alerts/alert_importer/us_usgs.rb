# frozen_string_literal: true

require 'json'
require 'net/http'
require 'rgeo/geo_json'

module SafetyAlerts
  # Alert importer for New Zealand's GeoNet earthquake service
  module AlertImporter::US_USGS
    def self.run(db)
      response =
        Net::HTTP.get('www.rfs.nsw.gov.au', '/feeds/majorIncidents.json')

      collection = RGeo::GeoJSON.decode(response)

      collection.each do |f|
        description = "#{f.property('title')} at TIME"

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

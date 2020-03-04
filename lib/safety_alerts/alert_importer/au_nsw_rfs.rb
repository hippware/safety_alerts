# frozen_string_literal: true

require 'json'
require 'net/http'
require 'rgeo/geo_json'

module SafetyAlerts
  # Alert importer for the New South Wales Rural Fire Service in Australia.
  module AlertImporter::AU_NSW_RFS
    def self.run(db)
      response =
        Net::HTTP.get('www.rfs.nsw.gov.au', '/feeds/majorIncidents.json')

      collection = RGeo::GeoJSON.decode(response)

      collection.each do |f|
        db.insert_alert(
          id: f.property('guid'),
          expires_at: nil,
          title: f.property('title'),
          summary: f.property('description'),
          link: f.property('link'),
          geometry: f.geometry.as_text,
          data: JSON.dump(RGeo::GeoJSON.encode(f))
        )
      end

      collection.size
    end
  end
end

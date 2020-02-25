require 'json'
require 'net/http'
require 'rgeo/geo_json'

module SafetyAlerts
  module Importer
    module AU_NSW_RFS
      def self.run
        AlertDB.with_connection('AU_NSW_RFS') do |db|
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
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'json'
require 'net/http'
require 'rgeo/shapefile'

module SafetyAlerts
  module GeometryImporter::US_NWS
    DATA_DIR = '/tmp/US_NWS_geometry'
    BASE_URL = 'https://www.weather.gov/source/gis/Shapefiles/WSOM'
    REV = 'z_03mr20'

    def self.run(db)
      FileUtils.mkdir(DATA_DIR)
      filename = download(DATA_DIR, BASE_URL, REV)

      system("unzip -qq -d #{DATA_DIR} #{filename}")

      count = 0
      RGeo::Shapefile::Reader.open("#{DATA_DIR}/#{REV}.shp") do |file|
        file.each do |record|
          db.insert_geometry(
            id: record.attributes["STATE_ZONE"],
            geometry: record.geometry,
            data: JSON.dump(record.attributes)
          )

          count += 1
        end
      end

      FileUtils.rm_rf(DATA_DIR)

      count
    end

    def self.download(data_dir, base_url, rev)
      basename = "#{rev}.zip"
      filename = "#{data_dir}/#{basename}"
      uri = URI("#{base_url}/#{basename}")

      Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        request = Net::HTTP::Get.new uri

        http.request request do |response|
          open filename, 'w' do |io|
            response.read_body do |chunk|
              io.write chunk
            end
          end
        end
      end

      filename
    end
  end
end

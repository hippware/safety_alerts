require 'json'
require 'net/ftp'
require 'nokogiri'
require 'rgeo/geo_json'
require 'rgeo/shapefile'

module SafetyAlerts
  module Importer
    module AU_BOM
      def self.load_shapes
        shapes = Hash.new
        shape_files = Dir['lib/safety_alerts/importer/au_bom_spatial/*.shp']
        shape_files.each do |f|
          RGeo::Shapefile::Reader.open(f) do |file|
            file.each do |record|
              if record.attributes["AAC"] then
                shapes[record.attributes["AAC"]] =
                  RGeo::GeoJSON.encode(record.geometry).to_json
              end
            end
          end
        end

        shapes
      end

      def self.run
        shapes = load_shapes()

        AlertDB.with_connection('AU_BOM') do |db|
          count = 0

          # GRab all the amoc.xml files from the forecasts/warnings/observations
          # directory
          ftp = Net::FTP.new('ftp.bom.gov.au')
          ftp.login
          ftp.chdir('anon/gen/fwo')
          files = ftp.nlst('*.amoc.xml')
          files.each do |f|
            data = ftp.getbinaryfile(f, nil)
            doc = Nokogiri::XML(data)
            product_type = doc.xpath('amoc/product-type/text()')

            # Only worry about warnings (warnings tend to be 1:1
            # with a single "weather event" or similar
            if product_type.to_s == 'W' then
              expiry = doc.xpath('/amoc/expiry-time/text()')
              root_id = doc.xpath('amoc/incident-id/text()')

              # Each warning can contain multiple "hazards" - eg
              # multiple different warning levels for a storm
              # depending on the areas involved
              hazards = doc.xpath('/amoc/hazard')
              hazards.each do |h|
                title = h.xpath('./headline/text()')
                index = h.xpath('@index')
                id = root_id.to_s + '-' + index.to_s

                # Each hazard can cover multiple areas
                areas = h.xpath('./area-list')
                areas.each do |a|
                  if a.xpath('./area/@aac') then
                    puts a.xpath('./area/@aac').to_s
                    db.insert_alert(
                      id: id,
                      expires_at: expiry,
                      title: title,
                      summary: a.xpath('./area/@description').to_s,
                      link: nil,
                      geometry: shapes[a.xpath('./area/@aac').to_s],
                      data: nil
                    )
                    ++count
                  end
                end
              end
            end

            count
          end
        end
      end
    end
  end
end

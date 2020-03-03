# frozen_string_literal: true

require 'json'
require 'net/ftp'
require 'nokogiri'
require 'rgeo/geo_json'
require 'rgeo/shapefile'

module SafetyAlerts
  module AlertImporter::AU_BOM
    def self.run(db)
      count = 0

      # Grab all the amoc.xml files from the forecasts/warnings/observations
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
        # with a single "weather event" or similar)
        next unless product_type.to_s == 'W'

        expiry = doc.xpath('/amoc/expiry-time/text()')
        root_id = doc.xpath('/amoc/identifier/text()')

        # Each warning can contain multiple "hazards" - eg
        # multiple different warning levels for a storm
        # depending on the areas involved
        hazards = doc.xpath('/amoc/hazard')
        hazards.each do |h|
          title = h.xpath('./headline/text()')
          index = h.xpath('@index')
          id = root_id.to_s + '-' + index.to_s

          # Each hazard can cover multiple areas
          areas = h.xpath('./area-list/area')
          geometry = nil
          description = []
          areas.each do |a|
            aac = a.xpath('@aac').to_s
            if aac
              g = db.get_geometry(aac)
              if geometry
                geometry += g
              else
                geometry = g
              end
            end
            description.push(a.xpath('@description').to_s)
          end

          next unless geometry

          db.insert_alert(
            id: id,
            expires_at: expiry,
            title: title,
            summary: description.join('; '),
            link: nil,
            geometry: geometry,
            data: '{}'
          )

          count += 1
        end
      end

      count
    end
  end
end

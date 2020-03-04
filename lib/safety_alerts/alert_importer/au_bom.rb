# frozen_string_literal: true

require 'json'
require 'net/ftp'
require 'nokogiri'
require 'rgeo/geo_json'
require 'rgeo/shapefile'

module SafetyAlerts
  module AlertImporter::AU_BOM
    def self.run(db)
      # Grab all the amoc.xml files from the forecasts/warnings/observations
      # directory
      ftp = Net::FTP.new('ftp.bom.gov.au')
      ftp.login
      ftp.chdir('anon/gen/fwo')

      ftp.nlst('*.amoc.xml').reduce(0) do |count, f|
        import_file(ftp, db, f, count)
      end
    end

    def self.import_file(ftp, db, file, count)
      data = ftp.getbinaryfile(file, nil)
      doc = Nokogiri::XML(data)
      product_type = doc.xpath('amoc/product-type/text()')

      # Only worry about warnings (warnings tend to be 1:1
      # with a single "weather event" or similar)
      return count unless product_type.to_s == 'W'

      expiry = doc.xpath('/amoc/expiry-time/text()')
      root_id = doc.xpath('/amoc/identifier/text()').to_s

      # Each warning can contain multiple "hazards" - eg
      # multiple different warning levels for a storm
      # depending on the areas involved
      doc.xpath('/amoc/hazard').reduce(count) do |c, h|
        import_hazard(db, root_id, expiry, h, c)
      end
    end

    def self.import_hazard(db, root_id, expiry, hazard, count)
      # Each hazard can cover multiple areas
      geometry, description =
        hazard.xpath('./area-list/area').reduce([nil, []]) do |m, a|
          parse_area(db, a, m.first, m.last)
        end

      return count unless geometry

      index = hazard.xpath('@index').to_s

      db.insert_alert(
        id: "#{root_id}-#{index}",
        expires_at: expiry,
        title: hazard.xpath('./headline/text()'),
        summary: description.join('; '),
        link: nil,
        geometry: geometry,
        data: '{}'
      )

      count + 1
    end

    def self.parse_area(db, area, geometry, description)
      aac = area.xpath('@aac').to_s
      if aac
        g = db.get_geometry(aac)
        if geometry
          geometry += g
        else
          geometry = g
        end
      end

      [geometry, description.push(area.xpath('@description').to_s)]
    end
  end
end

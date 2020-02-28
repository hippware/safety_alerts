require 'json'
require 'net/ftp'
require 'nokogiri'
require 'rgeo/geo_json'
require 'rgeo/shapefile'

module SafetyAlerts
  module Importer
    module AU_BOM
      def self.run
        count = 0
        AlertDB.with_connection('AU_BOM') do |db|
          db.conn.prepare 'get_geometry', <<~SQL.strip
                    SELECT geometry FROM safety_alerts_geometries
                    WHERE source = 'AU_BOM' AND source_id = $1
          SQL

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
            # with a single "weather event" or similar
            if product_type.to_s == 'W' then
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
                puts id

                # Each hazard can cover multiple areas
                areas = h.xpath('./area-list/area')
                geometry = nil
                description = []
                areas.each do |a|
                  aac = a.xpath('@aac').to_s
                  if aac then
                    g = db.conn.exec_prepared('get_geometry', [aac]).getvalue(0, 0)
                    if geometry then
                      geometry += g
                    else
                      geometry = g
                    end
                  end
                  description.push(a.xpath('@description').to_s)
                end

                if geometry then
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
            end
          end
        end
      end

      count
    end
  end
end

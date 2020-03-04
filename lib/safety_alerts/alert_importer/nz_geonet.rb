# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'rgeo'
require 'rss'

module SafetyAlerts
  # Alert importer for New Zealand's GeoNet earthquake service
  module AlertImporter::NZ_GEONET
    def self.run(db)
      feed = RSS::Parser.parse(
        'http://api.geonet.org.nz/cap/1.2/GPA1.0/feed/atom1.0/quake', false
      )
      feed.items.reduce(0) do |count, item|
        item.links.each do |link|
          link.type == 'application/cap+xml' || next
          import_item(link.href, db, count)
          count += 1
        end
      end
    end

    def self.import_item(href, db)
      doc = Nokogiri::XML(URI.open(href)).remove_namespaces!

      id = doc.xpath('alert/identifier/text()').to_s

      description = info_field('description')
      instruction = info_field('instruction')
      summary = "<p>#{description}</p><p>#{instruction}</p>"

      geometry = make_geometry(info_field('area'))

      db.insert_alert(
        id: id,
        expires_at: info_field('expires'),
        title: info_field('headline'),
        summary: summary,
        link: info_field('web'),
        geometry: geometry,
        data: '{}'
      )
    end

    def self.info_field(doc, field)
      doc.xpath("alert/info/#{field}/text())").to_s
    end

    def self.make_geometry(location)
      format = /(-?[0-9]+(\.[0-9]+)?),(-?[0-9]+(\.[0-9]+)?) ([0-9]+(\.[0-9]+)?)/
      m = location.match(format)
      lat = m[1].to_f
      lon = m[3].to_f
      radius = m[5].to_f * 1000.0

      factory = RGeo::Geographic.spherical_factory(buffer_resolution: 10)
      factory.point(lon, lat).buffer(radius)
    end
  end
end

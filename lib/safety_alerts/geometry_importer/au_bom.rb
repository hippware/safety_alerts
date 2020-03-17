# frozen_string_literal: true

require 'net/ftp'
require 'nokogiri'
require 'pathname'
require 'rgeo/shapefile'
require 'tempfile'

module SafetyAlerts
  # Geometry importer for the Australian Bureau of Meteorology.
  module GeometryImporter::AU_BOM
    def self.run(db)
      ftp = Net::FTP.new('ftp.bom.gov.au')
      ftp.login
      ftp.chdir('anon/home/adfd/spatial')

      ftp.nlst('*.shp').reduce(0) do |c, f|
        base = Pathname.new(f).basename('.shp').to_s + '.'
        %w[shp shx dbf].each do |ext|
          ftp.getbinaryfile(base + ext, '/tmp/source.' + ext)
        end

        import_shapefile(db, '/tmp/source.shp', c)
      end
    end

    def self.import_shapefile(db, filename, count)
      RGeo::Shapefile::Reader.open(filename) do |f|
        f.each { |r| count += 1 if import_record(db, r) }
      end

      count
    end

    def self.import_record(db, record)
      return false unless record.attributes['AAC']

      db.insert_geometry(
        id: record.attributes['AAC'],
        geometry: record.geometry,
        data: record.attributes
      )

      true
    end
  end
end

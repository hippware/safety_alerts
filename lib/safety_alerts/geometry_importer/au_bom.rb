# frozen_string_literal: true

require 'json'
require 'net/ftp'
require 'nokogiri'
require 'pathname'
require 'rgeo/geo_json'
require 'rgeo/shapefile'
require 'tempfile'

module SafetyAlerts
  module GeometryImporter::AU_BOM
    def self.run(db)
      ftp = Net::FTP.new('ftp.bom.gov.au')
      ftp.login
      ftp.chdir('anon/home/adfd/spatial')

      ftp.nlst('*.shp').reduce(0) { |c, f| import_shapefile(ftp, db, f, c) }
    end

    def self.import_shapefile(ftp, db, file, count)
      base = Pathname.new(file).basename('.shp').to_s + '.'
      %w[shp shx dbf].each do |ext|
        puts "Getting #{base + ext}"
        ftp.getbinaryfile(base + ext, '/tmp/source.' + ext)
      end

      RGeo::Shapefile::Reader.open('/tmp/source.shp') do |f|
        f.each { |r| count += 1 if import_record(db, r) }
      end

      count
    end

    def self.import_record(db, record)
      return false unless record.attributes['AAC']

      db.insert_geometry(
        id: record.attributes['AAC'],
        geometry: record.geometry,
        data: JSON.dump(record.attributes)
      )

      true
    end
  end
end

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
      count = 0

      ftp = Net::FTP.new('ftp.bom.gov.au')
      ftp.login
      ftp.chdir('anon/home/adfd/spatial')
      files = ftp.nlst('*.shp')

      files.each do |f|
        base = Pathname.new(f).basename('.shp').to_s + '.'
        ['shp', 'shx', 'dbf'].each do |ext|
          puts "Getting #{base + ext}"
          ftp.getbinaryfile(base + ext, '/tmp/source.' + ext)
        end

        RGeo::Shapefile::Reader.open('/tmp/source.shp') do |file|
          file.each do |record|
            if record.attributes["AAC"] then
              db.insert_geometry(
                id: record.attributes["AAC"],
                geometry: record.geometry,
                data: '{}'
              )
              count += 1
            end
          end
        end
      end

      count
    end
  end
end

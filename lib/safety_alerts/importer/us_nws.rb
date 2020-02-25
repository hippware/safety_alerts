require 'gull'
require 'json'

module SafetyAlerts
  module Importer
    module US_NWS
      def self.run
        AlertDB.with_connection('US_NWS') do |db|
          Gull::Alert.fetch.each do |alert|
            ugcs =
              alert.geocode.ugc.split(" ").map do |code|
                code.sub(/([A-Z][A-Z])[CZ]([0-9]*)/, '\1\2')
              end

            geometry = db.get_one <<~SQL.strip
            SELECT ST_Union(ugc.geom) as polygon
            FROM (
              SELECT geom
              FROM ugc_lookup
              WHERE state_zone IN (#{ugcs.map {|id| "'#{id}'"}.join(',')})
            ) AS ugc;
            SQL

            if geometry
              data = Utils.hashify(alert)
              data['geocode'] = Utils.hashify(alert.geocode)

              db.insert_alert(
                id: alert.id,
                expires_at: alert.expires_at,
                title: alert.title,
                summary: alert.summary,
                link: alert.link,
                geometry: geometry,
                data: data.to_json
              )
            end
          end
        end
      end
    end
  end
end

require 'gull'
require 'json'
require 'pg'

SOURCE = 'US_NWS'

db_host = ENV['WOCKY_DB_HOST'] || 'localhost'
db_name = ENV['WOCKY_DB_NAME'] || 'wocky_dev'
db_user = ENV['WOCKY_DB_USER'] || 'postgres'

def hashify(obj)
  obj.instance_variables.each_with_object({}) do |var, hash|
    hash[var.to_s.delete("@")] = obj.instance_variable_get(var)
  end
end

begin
  conn = PG.connect :host => db_host, :dbname => db_name, :user => db_user

  conn.prepare 'insert_alert', <<~SQL.strip
  INSERT INTO safety_alerts (
    id,
    source,
    source_id,
    created_at,
    updated_at,
    expires_at,
    title,
    summary,
    link,
    geometry,
    data
  ) VALUES (
    uuid_generate_v4(),
    '#{SOURCE}',
    $1,
    now(),
    now(),
    $2,
    $3,
    $4,
    $5,
    $6,
    $7
  ) ON CONFLICT (source, source_id) DO
  UPDATE SET
    updated_at=now(),
    expires_at=$2,
    title=$3,
    summary=$4,
    link=$5,
    geometry=$6,
    data=$7
  SQL

  Gull::Alert.fetch.each do |alert|
    ugcs =
      alert.geocode.ugc.split(" ").map do |code|
        code.sub(/([A-Z][A-Z])[CZ]([0-9]*)/, '\1\2')
      end

    rs = conn.exec <<~SQL.strip
    SELECT ST_Union(ugc.geom) as polygon
    FROM (
      SELECT geom
      FROM ugc_lookup
      WHERE state_zone IN (#{ugcs.map {|id| "'#{id}'"}.join(',')})
    ) AS ugc;
    SQL

    geometry = rs.getvalue(0, 0)

    if geometry
      data = hashify(alert)
      data['geocode'] = hashify(alert.geocode)

      conn.exec_prepared 'insert_alert', [
        alert.id,
        alert.expires_at,
        alert.title,
        alert.summary,
        alert.link,
        geometry,
        data.to_json
      ]
    end
  end
rescue PG::Error => e
  puts e.message
ensure
  conn.close if conn
end

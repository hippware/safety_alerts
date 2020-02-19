require 'gull'
require 'pg'

begin
  conn = PG.connect :dbname => 'wocky_dev', :user => 'postgres'

  conn.prepare 'insert_alert', <<~SQL.strip
  INSERT INTO nws_alerts (
    id, alert_type, title, summary, effective_at, expires_at, published_at,
    area, polygon, geocode_fips6, geocode_ugc, urgency, severity, certainty,
    vtec, geometry
  ) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16
  );
  SQL

  Gull::Alert.fetch.each do |alert|
    ugcs =
      alert.geocode.ugc.split(" ").map do |code|
        code.sub(/([A-Z][A-Z])[CZ]([0-9]*)/, '\1\2')
      end

    rs = conn.exec <<~SQL.strip
    SELECT ST_AsEWKT(ST_Union(ugc.geom)) as polygon
    FROM (
      SELECT geom
      FROM ugc_lookup
      WHERE state_zone IN (#{ugcs.map {|id| "'#{id}'"}.join(',')})
    ) AS ugc;
    SQL

    conn.exec_prepared 'insert_alert', [
      alert.id,
      alert.alert_type,
      alert.title,
      alert.summary,
      alert.effective_at,
      alert.expires_at,
      alert.published_at,
      alert.area,
      alert.polygon,
      alert.geocode.fips6,
      alert.geocode.ugc,
      alert.urgency,
      alert.severity,
      alert.certainty,
      alert.vtec,
      rs.getvalue(0, 0)
    ]
  end
rescue PG::Error => e
  puts e.message
ensure
  conn.close if conn
end

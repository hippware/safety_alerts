module SafetyAlerts
  class AlertGeometryDB < DB
    class << self
      def with_connection(source, &block)
        db = AlertGeometryDB.new(source)

        block.call(db)
      rescue PG::Error => e
        puts e.message
      ensure
        db&.close
      end
    end

    def initialize(source)
      super(source)

      @conn.prepare 'insert_geometry', <<~SQL.strip
      INSERT INTO safety_alerts_geometries (
        source,
        source_id,
        created_at,
        updated_at,
        geometry,
        data
      ) VALUES (
        '#{source}',
        $1,
        now(),
        now(),
        $2,
        $3
      ) ON CONFLICT (source, source_id) DO
      UPDATE SET
        updated_at=now(),
        geometry=$2,
        data=$3
      SQL
    end

    def insert_geometry(id:, geometry:, data:)
      @conn.exec_prepared 'insert_geometry', [
        id,
        geometry,
        data
      ]
    end
  end
end

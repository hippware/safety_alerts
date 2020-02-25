require 'pg'

module SafetyAlerts
  class AlertDB
    class << self
      def with_connection(source, &block)
        db = AlertDB.new(source)

        block.call(db)
      rescue PG::Error => e
        puts e.message
      ensure
        db&.close
      end
    end

    def initialize(source)
      @source = source

      @db_host = ENV['WOCKY_DB_HOST'] || 'localhost'
      @db_name = ENV['WOCKY_DB_NAME'] || 'wocky_dev'
      @db_user = ENV['WOCKY_DB_USER'] || 'postgres'
      @db_pass = ENV['WOCKY_DB_PASSWORD'] || ''

      @conn = PG.connect(
        :host => @db_host,
        :dbname => @db_name,
        :user => @db_user,
        :password => @db_pass
      )

      @conn.prepare 'insert_alert', <<~SQL.strip
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
        '#{@source}',
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
    end

    def close
      @conn.close
    end

    def get_one(sql)
      rs = @conn.exec(sql)
      rs.getvalue(0, 0)
    end

    def insert_alert(id:, expires_at:, title:, summary:, link:, geometry:, data:)
      @conn.exec_prepared 'insert_alert', [
        id,
        expires_at,
        title,
        summary,
        link,
        geometry,
        data
      ]
    end
  end
end

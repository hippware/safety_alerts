require 'pg'

module SafetyAlerts
  class AlertDB
    class << self
      def run_imports_for(source, &block)
        db = AlertDB.new(source)

        db.prepare_import

        count = block.call(db)

        db.delete_stale

        count
      rescue PG::Error => e
        puts e.message
      ensure
        db&.close
      end
    end

    attr_reader :source

    def initialize(source)
      @source = source

      secrets = Secrets.new

      @conn = PG.connect(
        :host     => ENV['WOCKY_DB_HOST'] || 'localhost',
        :dbname   => ENV['WOCKY_DB_NAME'] || 'wocky_dev',
        :user     => ENV['WOCKY_DB_USER'] || 'postgres',
        :password => secrets.get_value('db-password')
      )

      @conn.prepare 'reset_imported', <<~SQL
      UPDATE safety_alerts SET imported = false
        WHERE source = '#{@source}'
      SQL

      @conn.prepare 'delete_stale', <<~SQL
      DELETE FROM safety_alerts
      WHERE source = '#{@source}'
        AND imported = false
      SQL

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
        data,
        imported
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
        $7,
        true
      ) ON CONFLICT (source, source_id) DO
      UPDATE SET
        updated_at=now(),
        expires_at=$2,
        title=$3,
        summary=$4,
        link=$5,
        geometry=$6,
        data=$7,
        imported=true
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

    def prepare_import
      @conn.exec_prepared 'reset_imported'
    end

    def delete_stale
      @conn.exec_prepared 'delete_stale'
    end
  end
end

# frozen_string_literal: true

require 'pg'

module SafetyAlerts
  # Manages the database connection for the alerts and geometries tables.
  class DB
    attr_reader :source, :conn

    def initialize(source)
      @source = source

      @conn = PG.connect(
        host: ENV['WOCKY_DB_HOST'] || 'localhost',
        user: ENV['WOCKY_DB_USER'] || 'postgres',
        dbname: ENV['WOCKY_DB_NAME'] || 'wocky_dev',
        password: Secrets.get_value('db-password')
      )
    end

    def close
      @conn.close
    end

    def get_one(sql)
      @conn.exec(sql).getvalue(0, 0)
    end

    def prepare_alert_import
      @conn.prepare 'insert_alert', <<~SQL.strip
        INSERT INTO safety_alerts (
          id, source, source_id, created_at, updated_at, expires_at, title,
          summary, link, geometry, data, imported
        )
        VALUES (
          uuid_generate_v4(), '#{@source}', $1, now(), now(), $2, $3,
          $4, $5, $6, $7, true
        )
        ON CONFLICT (source, source_id) DO UPDATE
          SET updated_at=now(),
              expires_at=$2,
              title=$3,
              summary=$4,
              link=$5,
              geometry=$6,
              data=$7,
              imported=true
      SQL

      @conn.prepare 'get_geometry', <<~SQL.strip
        SELECT geometry FROM safety_alerts_geometries
        WHERE source = '#{@source}' AND source_id = $1
      SQL

      @conn.exec <<~SQL
        UPDATE safety_alerts SET imported = false
        WHERE source = '#{@source}'
      SQL
    end

    def get_geometry(id)
      @conn.exec_prepared('get_geometry', [id]).getvalue(0, 0)
    end

    def get_geometry_union(ids)
      get_one <<~SQL.strip
        SELECT ST_Union(ugc.geometry) as polygon
        FROM (
          SELECT geometry
          FROM safety_alerts_geometries
          WHERE source = '#{@source}'
            AND source_id IN (#{ids.map { |id| "'#{id}'" }.join(',')})
        ) AS ugc;
      SQL
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

    def delete_stale_alerts
      @conn.exec <<~SQL
        DELETE FROM safety_alerts
        WHERE source = '#{@source}'
          AND imported = false
      SQL
    end

    def prepare_geometry_import
      @conn.prepare 'insert_geometry', <<~SQL.strip
        INSERT INTO safety_alerts_geometries (
          source, source_id, created_at, updated_at, geometry, data
        )
        VALUES (
          '#{@source}', $1, now(), now(), $2, $3
        )
        ON CONFLICT (source, source_id) DO UPDATE
          SET updated_at=now(),
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

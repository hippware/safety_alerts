# frozen_string_literal: true

require 'faraday'
require 'json'
require 'rgeo/geo_json'

module SafetyAlerts
  # Abstracts the backend web service in Wocky.
  class DB
    URL_BASE_PATH = '/api/v1/safety'

    attr_reader :source, :conn

    def initialize(source)
      @source = source

      host = ENV['WOCKY_HOST'] || 'localhost'

      if host == 'localhost'
        scheme = 'http'
        port = 4000
      else
        scheme = 'https'
        port = 443
      end

      @conn = Faraday.new(
        url: "#{scheme}://#{host}:#{port}/#{URL_BASE_PATH}/",
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    def prepare_alert_import
      resp = @conn.put("alerts/#{@source}/import")

      resp.status == 204
    end

    def insert_alert(id:, expires_at:, title:, summary:, link:, geometry:, data:)
      packet = {
        id: id,
        expires_at: expires_at,
        title: title,
        summary: summary,
        link: link,
        geometry: geometry,
        data: data
      }

      resp = @conn.put("alerts/#{@source}/#{id}") do |req|
        req.body = packet.to_json
      end

      resp.status == 201
    end

    def delete_stale_alerts
      resp = @conn.delete("alerts/#{@source}/import")

      resp.status == 204
    end

    def insert_geometry(id:, geometry:, data:)
      packet = {
        id: id,
        data: data,
        geometry: RGeo::GeoJSON.encode(geometry)
      }

      resp = @conn.put("geometries/#{@source}/#{id}") do |req|
        req.body = packet.to_json
      end

      resp.status == 201
    end
  end
end

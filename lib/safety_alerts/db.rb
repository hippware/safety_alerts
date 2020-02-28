require 'pg'

module SafetyAlerts
  class DB
    attr_reader :source, :conn

    def initialize(source)
      @source = source

      secrets = Secrets.new

      @conn = PG.connect(
        :host     => ENV['WOCKY_DB_HOST'] || 'localhost',
        :dbname   => ENV['WOCKY_DB_NAME'] || 'wocky_dev',
        :user     => ENV['WOCKY_DB_USER'] || 'postgres',
        :password => secrets.get_value('db-password')
      )
    end

    def close
      @conn.close
    end

    def get_one(sql)
      rs = @conn.exec(sql)
      rs.getvalue(0, 0)
    end
  end
end


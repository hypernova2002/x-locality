# frozen_string_literal: true

Hanami.app.register_provider(:db) do
  prepare do
    require 'sequel'
  end

  start do
    # Explicit, not incidental - store and read every timestamp as UTC
    # regardless of the host/container's own TZ. Ruby's Time.now is also
    # pinned to UTC via ENV["TZ"] (see docker-compose).
    Sequel.default_timezone = :utc

    db = Sequel.connect(target['settings'].database_url)
    db.extension :pg_array
    Sequel::Model.db = db
    Sequel::Model.plugin :timestamps, update_on_create: true
    register 'db', db
  end

  stop do
    target['db'].disconnect
  end
end

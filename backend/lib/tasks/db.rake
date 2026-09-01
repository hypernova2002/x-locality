# frozen_string_literal: true

namespace :db do
  desc "Run pending Sequel migrations"
  task :migrate do
    require "sequel"

    database_url = ENV.fetch("DATABASE_URL")
    Sequel.connect(database_url) do |db|
      Sequel.extension :migration
      Sequel::Migrator.run(db, "db/migrate")
    end

    puts "Migrations complete."
  end

  desc "Roll back the last migration"
  task :rollback do
    require "sequel"

    database_url = ENV.fetch("DATABASE_URL")
    Sequel.connect(database_url) do |db|
      Sequel.extension :migration
      current = Sequel::Migrator.get_current_migration_version(db, "db/migrate")
      versions = Sequel::Migrator.migration_files("db/migrate").map { |f| File.basename(f).to_i }.sort
      target = versions[versions.index(current) - 1] || 0
      Sequel::Migrator.run(db, "db/migrate", target: target)
    end

    puts "Rolled back."
  end

  namespace :test do
    desc "Create (if needed) and migrate the test database"
    task :prepare do
      require "sequel"
      require "uri"

      test_url = ENV.fetch("DATABASE_URL").sub(/x_locality_development\z/, "x_locality_test")
      uri = URI(test_url)
      db_name = uri.path.delete_prefix("/")
      admin_url = test_url.sub("/#{db_name}", "/postgres")

      Sequel.connect(admin_url) do |db|
        exists = db[:pg_database].where(datname: db_name).count > 0
        db.run("CREATE DATABASE #{db_name}") unless exists
      end

      Sequel.connect(test_url) do |db|
        Sequel.extension :migration
        Sequel::Migrator.run(db, "db/migrate")
      end

      puts "Test database ready."
    end
  end
end

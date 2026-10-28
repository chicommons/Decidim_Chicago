# Run with: bundle exec rails runner bin/railway-release.rb
# Never db:prepare/db:setup: the repository's seeds create demo organizations.
connection = ActiveRecord::Base.connection
schema = ENV.fetch("DATABASE_SCHEMA", "public")
abort "Invalid DATABASE_SCHEMA" unless schema.match?(/\A[a-z_][a-z0-9_]*\z/)
connection.execute("CREATE SCHEMA IF NOT EXISTS #{connection.quote_column_name(schema)}")
tables = connection.select_values(
  "SELECT tablename FROM pg_tables WHERE schemaname = #{connection.quote(schema)}"
)
if (tables - %w[schema_migrations ar_internal_metadata]).any? && !tables.include?("decidim_organizations")
  abort "Refusing migrations: target schema contains non-Decidim tables. Use a dedicated database/schema."
end

puts "PostgreSQL connected; checking Redis before applying migrations."
require "redis"
Redis.new(url: ENV.fetch("REDIS_URL"), connect_timeout: 10, read_timeout: 10).ping

puts "Migrating Decidim schema (no demo seeds)."
Rails.application.load_tasks
Rake::Task["db:migrate"].invoke
puts "Database migration completed."
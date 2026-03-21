# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", "0.31.2"
gem "decidim-demographics" # "0.31.2"

# loading any of these modules (in sequeunce) seems to lead to error
#  = /usr/local/bundle/gems/redis-4.8.1/lib/redis/client.rb:398:in
# `rescue in establish_connection': Error connecting to Redis on
# localhost:6379 (Errno::ECONNREFUSED) (Redis::CannotConnectError)
# these gems commented out in docker compose
gem "decidim-ai" # "0.31.2"
gem "decidim-collaborative_texts" # "0.31.2"
gem "decidim-conferences" # "0.31.2"
gem "decidim-design" # "0.31.2"
gem "decidim-elections" # "0.31.2"
gem "decidim-initiatives" # "0.31.2"
gem "decidim-templates" # "0.31.2"

gem "bootsnap", "~> 1.3"

gem "puma", ">= 6.3.1"

# added by barry for email service
gem "daemons"
gem "delayed_job"
gem "delayed_job_active_record", ">= 4.1.10"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "brakeman", "~> 7.0"
  gem "decidim-dev", "0.31.2"
  gem "net-imap", "~> 0.5.0"
  gem "net-pop", "~> 0.1.1"
end

group :development do
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "web-console", "~> 4.2"
end
gem "sidekiq"

group :production do
end

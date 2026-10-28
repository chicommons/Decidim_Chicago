require_relative "boot"

require "decidim/rails"

# Add the frameworks used by your app that are not loaded by Decidim.
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Code
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Environment-only deployments can choose a separate credentials file.
    # This avoids mixing the generated image's key with repository credentials.
    if ENV["RAILS_CREDENTIALS_PATH"].present?
      config.credentials.content_path = Rails.root.join(ENV.fetch("RAILS_CREDENTIALS_PATH"))
    end

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Central Time (US & Canada)"
    # ShowExceptions captures its error app while the middleware stack builds.
    # after_initialize is too late. A DB failure occurs before Warden runs,
    # so Decidim's authenticated error renderer cannot safely handle it.
    initializer "code.production_exceptions", after: "decidim_core.exceptions_app", before: :build_middleware_stack do |app|
      if Rails.env.production?
        app.config.exceptions_app = ActionDispatch::PublicExceptions.new(Rails.public_path)
      end
    end

    # Engine classifiers are initialized before config/initializers/*.rb.
    # Configure them here so REDIS_URL is effective from the first boot.
    initializer "code.ai_backends", before: "decidim_ai.resource_classifiers" do
      require Rails.root.join("lib/code/namespaced_bayes")
      %w[resource user].each do |kind|
        prefix = "DECIDIM_SPAM_DETECTION_BACKEND_#{kind.upcase}"
        url = ENV["#{prefix}_REDIS_URL"] || ENV["#{prefix}_URL"] || ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
        analyzers = [{
          name: :bayes,
          strategy: Code::NamespacedBayes,
          options: {
            adapter: ENV.fetch(prefix, "redis"),
            params: { url: url, namespace: "decidim:ai:#{kind}" }
          }
        }]
        Decidim::Ai::SpamDetection.public_send("#{kind}_analyzers=", analyzers)
      end
    end
    # config.eager_load_paths << Rails.root.join("extras")
  end
end

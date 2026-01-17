require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  config.active_storage.service = :local

  config.assume_ssl = true
  config.force_ssl = true

  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  # Use environment variable for flexibility, fallback to your Render domain
  app_host = ENV.fetch("APP_HOST", "autobio-app.onrender.com")

  config.action_mailer.default_url_options = {
    host: app_host,
    protocol: "https"
  }

  config.action_controller.default_url_options = {
    host: app_host,
    protocol: "https"
  }

  # Whitelist your Render domain to prevent 403 Forbidden errors
#  config.hosts = [
#    "autobio-app.onrender.com",
#    /.*\.autobio-app\.onrender\.com/
#  ]

  # Allow health check endpoint without host authorization
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end

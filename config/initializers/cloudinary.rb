if ENV["CLOUDINARY_CLOUD_NAME"].present?
  require "cloudinary"
  Cloudinary.config do |config|
    config.cloud_name = ENV["CLOUDINARY_CLOUD_NAME"]
    config.api_key    = ENV["CLOUDINARY_API_KEY"]
    config.api_secret = ENV["CLOUDINARY_API_SECRET"]
    config.secure     = true
  end
end
# Cloudinary configuration for Rails
# This file is automatically loaded when the app starts

if Rails.env.production?
  # Production uses Cloudinary via Active Storage
  # Configuration is handled in config/storage.yml
  Rails.logger.info "🌤️  Cloudinary configured for production image storage"
else
  # Development and test use local storage
  Rails.logger.info "💾 Local storage configured for #{Rails.env} environment"
end

require "cloudinary"
require Rails.root.join("lib/active_storage/service/cloudinary_custom_service")

# Explicit Cloudinary config
Cloudinary.config do |config|
  config.cloud_name = ENV["CLOUDINARY_CLOUD_NAME"].to_s.strip
  config.api_key    = ENV["CLOUDINARY_API_KEY"].to_s.strip
  config.api_secret = ENV["CLOUDINARY_API_SECRET"].to_s.strip
  config.secure     = true
end

if Rails.env.production?
  Rails.logger.info "🌤️  Cloudinary configured for production image storage"
else
  Rails.logger.info "💾 Local storage configured for #{Rails.env} environment"
end

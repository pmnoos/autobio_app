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

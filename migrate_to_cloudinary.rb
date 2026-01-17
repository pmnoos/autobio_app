#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to migrate Active Storage blobs from local storage to Cloudinary
# Usage: rails runner migrate_to_cloudinary.rb

require 'cloudinary'

puts "🔄 Starting migration to Cloudinary..."
puts "=" * 60

# Check Cloudinary configuration
unless ENV['CLOUDINARY_CLOUD_NAME'].present? &&
       ENV['CLOUDINARY_API_KEY'].present? &&
       ENV['CLOUDINARY_API_SECRET'].present?
  puts "❌ Error: Cloudinary environment variables not set!"
  puts "Please set: CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET"
  exit 1
end

puts "✅ Cloudinary configured: #{ENV['CLOUDINARY_CLOUD_NAME']}"
puts

# Get all attachments that need migration
total_count = ActiveStorage::Attachment.count
puts "📊 Found #{total_count} attachments to process"
puts

migrated = 0
skipped = 0
errors = 0

ActiveStorage::Attachment.includes(:blob).find_each.with_index do |attachment, index|
  blob = attachment.blob

  print "[#{index + 1}/#{total_count}] Processing: #{blob.filename} (#{blob.byte_size} bytes)... "

  begin
    # Download the file from local storage using a block to ensure proper cleanup
    temp_file = Tempfile.new([ blob.filename.base, blob.filename.extension_with_delimiter ])
    temp_file.binmode
    temp_file.write(blob.download)
    temp_file.close

    # Upload to Cloudinary
    result = Cloudinary::Uploader.upload(
      temp_file.path,
      resource_type: 'auto',
      public_id: blob.key,
      folder: 'active_storage'
    )

    # Update the blob's metadata to point to Cloudinary
    blob.update_columns(
      service_name: 'cloudinary',
      key: result['public_id']
    )

    puts "✅ Migrated (#{result['secure_url']})"
    migrated += 1

  rescue => e
    puts "❌ Error: #{e.message}"
    errors += 1
  ensure
    # Let Windows clean up temp files automatically
    temp_file = nil
  end

  # Small delay to avoid rate limiting
  sleep 0.1
end

puts
puts "=" * 60
puts "🎉 Migration complete!"
puts "✅ Migrated: #{migrated}"
puts "⏭️  Skipped: #{skipped}"
puts "❌ Errors: #{errors}"
puts "=" * 60

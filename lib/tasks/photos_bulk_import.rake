# lib/tasks/photos_bulk_import.rake
#
# Bulk-import images from a local folder into the Photo gallery.
#
# USAGE
# -----
# 1. Drop your images into:  tmp/photos_import/
#    Supported formats: jpg, jpeg, png, gif, webp, avif
#
# 2. (Optional) Place a CSV beside the images to supply metadata:
#      tmp/photos_import/metadata.csv
#    Columns (all optional except filename):
#      filename, title, description, taken_at (YYYY-MM-DD)
#    Any image without a CSV row gets a title from its filename.
#
# 3. Run locally (development):
#      bundle exec rails photos:bulk_import
#
# 4. Dry-run (shows what would be imported, no DB writes):
#      DRY_RUN=1 bundle exec rails photos:bulk_import
#
# 5. Run against PRODUCTION from your local machine:
#      RAILS_ENV=production \
#      DATABASE_URL="postgresql://..." \
#      CLOUDINARY_CLOUD_NAME="..." \
#      CLOUDINARY_API_KEY="..." \
#      CLOUDINARY_API_SECRET="..." \
#      bundle exec rails photos:bulk_import

namespace :photos do
  desc "Bulk-import images from tmp/photos_import/ into the Photo gallery"
  task bulk_import: :environment do
    require "csv"
    import_dir = Rails.root.join("tmp", "photos_import")
    dry_run    = ENV["DRY_RUN"].present?

    unless import_dir.exist?
      puts "ERROR: Import folder not found: #{import_dir}"
      puts "Create it and place your images inside, then re-run."
      exit 1
    end

    extensions = %w[jpg jpeg png gif webp avif]
    image_files = Dir[import_dir.join("*")].select do |f|
      extensions.include?(File.extname(f).delete(".").downcase)
    end.sort

    if image_files.empty?
      puts "No images found in #{import_dir}"
      exit 0
    end

    puts "Found #{image_files.size} image(s) in #{import_dir}"
    puts "(DRY RUN — nothing will be saved)" if dry_run
    puts

    # Load optional metadata CSV
    metadata = {}
    csv_path = import_dir.join("metadata.csv")
    if csv_path.exist?
      CSV.foreach(csv_path, headers: true, header_converters: :symbol) do |row|
        filename = row[:filename].to_s.strip
        next if filename.empty?
        metadata[filename] = {
          title:       row[:title].to_s.strip.presence,
          description: row[:description].to_s.strip.presence,
          taken_at:    row[:taken_at].to_s.strip.presence
        }
      end
      puts "Loaded metadata for #{metadata.size} file(s) from metadata.csv"
      puts
    end

    imported = 0
    skipped  = 0
    errors   = 0

    image_files.each do |filepath|
      filename  = File.basename(filepath)
      meta      = metadata[filename] || {}

      # Default title: strip extension and underscores/dashes, titleize
      default_title = File.basename(filename, ".*")
                         .gsub(/[_\-]+/, " ")
                         .split
                         .map(&:capitalize)
                         .join(" ")

      title       = meta[:title].presence || default_title
      description = meta[:description]
      taken_at    = meta[:taken_at].present? ? Date.parse(meta[:taken_at]) : nil

      # Skip if a photo with the same title already exists (prevents re-importing)
      if Photo.exists?(title: title)
        puts "  SKIP  #{filename} — title '#{title}' already exists"
        skipped += 1
        next
      end

      if dry_run
        puts "  WOULD IMPORT  #{filename} → title: '#{title}'" \
             "#{taken_at ? ", taken_at: #{taken_at}" : ''}"
        imported += 1
        next
      end

      photo = Photo.new(title: title, description: description, taken_at: taken_at)
      photo.image.attach(
        io:           File.open(filepath),
        filename:     filename,
        content_type: Marcel::MimeType.for(Pathname.new(filepath))
      )

      if photo.save
        puts "  IMPORTED  #{filename} → Photo ##{photo.id} '#{title}'"
        imported += 1
      else
        puts "  ERROR     #{filename}: #{photo.errors.full_messages.join(', ')}"
        errors += 1
      end
    end

    puts
    puts "Done. Imported: #{imported}  |  Skipped (duplicate): #{skipped}  |  Errors: #{errors}"
  end
end

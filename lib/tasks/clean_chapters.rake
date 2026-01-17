namespace :chapters do
  desc "Remove all chapter photos to prepare for Cloudinary migration"
  task clean_photos: :environment do
    puts "🧹 Cleaning chapter photos..."

    count = 0
    Chapter.find_each do |chapter|
      if chapter.image_header.attached?
        chapter.image_header.purge
  end

  desc "Delete all chapters (use carefully!)"
  task delete_all: :environment do
    count = Chapter.count
    Chapter.destroy_all
    puts "✅ Deleted #{count} chapters"
  end
end

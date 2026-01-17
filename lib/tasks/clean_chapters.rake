namespace :chapters do
  desc "Remove all chapter photos to prepare for Cloudinary migration"
  task clean_photos: :environment do
    puts "🧹 Cleaning chapter photos..."

    count = 0
    Chapter.find_each do |chapter|
      if chapter.header_image.attached?
        chapter.header_image.purge
        count += 1
      end
    end

    puts "✅ Removed #{count} chapter photos"
    puts "You can now re-upload them and they will go to Cloudinary"
  end

  desc "Delete all chapters (use carefully!)"
  task delete_all: :environment do
    count = Chapter.count
    Chapter.destroy_all
    puts "✅ Deleted #{count} chapters"
  end
end

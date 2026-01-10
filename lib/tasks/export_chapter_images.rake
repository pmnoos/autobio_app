# lib/tasks/export_chapter_images.rake
namespace :chapters do
  desc "Export all chapter attached images to public/images folder"
  task export_images: :environment do
    require "fileutils"
    images_dir = Rails.root.join("public", "images")
    FileUtils.mkdir_p(images_dir)

    Chapter.find_each do |chapter|
      if chapter.respond_to?(:image_header) && chapter.image_header.attached?
        filename = "chapter_#{chapter.id}_header#{File.extname(chapter.image_header.filename.to_s)}"
        path = images_dir.join(filename)
        File.open(path, "wb") do |f|
          f.write(chapter.image_header.download)
        end
        puts "Exported: #{path}"
      end
      # Add more logic here if you have other image attachments in chapters
    end
    puts "All chapter images exported to #{images_dir}"
  end
end

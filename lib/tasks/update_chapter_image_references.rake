# lib/tasks/update_chapter_image_references.rake
namespace :chapters do
  desc "Update chapter content to reference exported images in public/images"
  task update_image_references: :environment do
    Chapter.find_each do |chapter|
      if chapter.respond_to?(:image_header) && chapter.image_header.attached?
        filename = "chapter_#{chapter.id}_header#{File.extname(chapter.image_header.filename.to_s)}"
        image_path = "/images/#{filename}"
        # Replace any <img> tags with src not pointing to /images/ with the correct path
        updated = chapter.content.to_s.gsub(/<img[^>]*src=["'](?!\/images\/)[^"']+["'][^>]*>/, "<img src='#{image_path}' />")
        if updated != chapter.content.to_s
          chapter.update(content: updated)
          puts "Updated chapter ##{chapter.id} image reference to #{image_path}"
        end
      end
    end
    puts "All chapter image references updated."
  end
end

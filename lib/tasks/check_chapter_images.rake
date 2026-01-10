# lib/tasks/check_chapter_images.rake
namespace :chapters do
  desc "Check all chapter image references and file existence in public/images"
  task check_images: :environment do
    require 'nokogiri'
    missing = []
    Chapter.find_each do |chapter|
      content = chapter.content.to_s
      doc = Nokogiri::HTML::DocumentFragment.parse(content)
      doc.css('img').each do |img|
        src = img['src']
        next unless src&.start_with?('/images/')
        path = Rails.root.join('public', src)
        unless File.exist?(path)
          missing << { chapter_id: chapter.id, src: src, expected_path: path.to_s }
          puts "Missing: Chapter ##{chapter.id} references #{src} (not found at #{path})"
        else
          puts "OK: Chapter ##{chapter.id} references #{src} (found)"
        end
      end
    end
    if missing.empty?
      puts "All chapter image references are valid."
    else
      puts "\nMissing images summary:"
      missing.each { |m| puts m.inspect }
    end
  end
end

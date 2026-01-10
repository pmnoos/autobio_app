# script/check_docx_images.rb
# Usage: ruby script/check_docx_images.rb path/to/your.docx
require 'zip'

docx_path = ARGV[0] || abort('Usage: ruby script/check_docx_images.rb path/to/your.docx')
image_files = []

Zip::File.open(docx_path) do |zip_file|
  zip_file.each do |entry|
    if entry.name.start_with?('word/media/')
      image_files << entry.name.sub('word/media/', '')
    end
  end
end

puts "Images embedded in #{docx_path}:"
image_files.each { |img| puts " - #{img}" }

# Optionally, compare to public/images
images_dir = File.expand_path('../../public/images', __dir__)
existing_images = Dir.entries(images_dir).select { |f| !File.directory?(File.join(images_dir, f)) }

puts "\nImages in public/images directory:"
existing_images.each { |img| puts " - #{img}" }

missing = image_files - existing_images
if missing.empty?
  puts "\nAll embedded images are present in public/images."
else
  puts "\nMissing in public/images:"
  missing.each { |img| puts " - #{img}" }
end

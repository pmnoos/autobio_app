# script/check_image_validity.rb
# Usage: ruby script/check_image_validity.rb
require 'mini_magick'

dir = File.expand_path('../../public/images', __dir__)
missing = []
invalid = []

Dir.glob(File.join(dir, '*')).each do |img_path|
  next if File.directory?(img_path)
  begin
    image = MiniMagick::Image.open(img_path)
    if image.width == 0 || image.height == 0
      invalid << img_path
      puts "Invalid image (zero size): #{img_path}"
    else
      puts "OK: #{img_path} (#{image.type}, #{image.width}x#{image.height})"
    end
  rescue => e
    invalid << img_path
    puts "Invalid image: #{img_path} (#{e.message})"
  end
end

if invalid.empty?
  puts "\nAll images in public/images are valid."
else
  puts "\nInvalid or unreadable images:"
  invalid.each { |img| puts " - #{img}" }
end

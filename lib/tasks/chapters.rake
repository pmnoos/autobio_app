require "json"
require "fileutils"

namespace :chapters do
  desc "Export chapters to JSON (tmp/chapters_export.json)"
  task export: :environment do
    chapters = Chapter.order(:created_at).map do |ch|
      {
        title: ch.title,
        subtitle: ch.subtitle,
        content_html: ch.content&.to_s,
        created_at: ch.created_at&.iso8601,
        updated_at: ch.updated_at&.iso8601
      }
    end

    FileUtils.mkdir_p("tmp")
    path = File.join("tmp", "chapters_export.json")
    File.write(path, JSON.pretty_generate(chapters))
    puts "✅ Exported #{chapters.size} chapters to #{path}"
    puts "Note: images (e.g., image_header) are not exported by this task."
  end

  desc "Import chapters from a local JSON file (default: tmp/chapters_export.json)"
  task :import, [ :path ] => :environment do |_, args|
    path = args[:path] || File.join("tmp", "chapters_export.json")
    unless File.exist?(path)
      abort "❌ File not found: #{path}"
    end

    data = JSON.parse(File.read(path))
    imported = 0
    data.each do |ch|
      Chapter.create!(
        title: ch["title"],
        subtitle: ch["subtitle"],
        content: ch["content_html"]
      )
      imported += 1
    end
    puts "✅ Imported #{imported} chapters from #{path}"
    puts "Reminder: images must be re-attached manually after import."
  end

  desc "Import chapters from a JSON URL (e.g., GitHub Gist raw URL)"
  task :import_url, [ :url ] => :environment do |_, args|
    url = args[:url]
    abort "❌ Provide a URL: rails chapters:import_url[https://...]" unless url

    require "open-uri"
    io = URI.open(url)
    data = JSON.parse(io.read)
    imported = 0
    data.each do |ch|
      Chapter.create!(
        title: ch["title"],
        subtitle: ch["subtitle"],
        content: ch["content_html"]
      )
      imported += 1
    end
    puts "✅ Imported #{imported} chapters from #{url}"
    puts "Reminder: images must be re-attached manually after import."
  end
end

desc "Force import chapters from chapters_import.rb (deletes existing chapters)"
task force_import_script: :environment do
  import_path = Rails.root.join("chapters_import.rb")
  unless File.exist?(import_path)
    abort "❌ File not found: #{import_path}"
  end

  puts "🧹 Removing all existing chapters (force import)"
  Chapter.delete_all

  puts "📥 Loading #{import_path}"
  load import_path

  puts "🔎 Backfilling special_type for known sections"
  Chapter.where("(special_type IS NULL OR special_type = '') AND (LOWER(title) LIKE ? OR LOWER(title) LIKE ?)", "%dedication%", "%didication%")
    .update_all(special_type: "dedication")
  Chapter.where("(special_type IS NULL OR special_type = '') AND LOWER(title) LIKE ?", "%intro%")
    .update_all(special_type: "introduction")
  Chapter.where("(special_type IS NULL OR special_type = '') AND LOWER(title) LIKE ?", "%epilogue%")
    .update_all(special_type: "epilogue")

  puts "✅ Force import complete"
end

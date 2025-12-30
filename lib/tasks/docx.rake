namespace :docx do
  desc "Export all chapters to a DOCX file (tmp/export/autobiography_complete_YYYYMMDD.docx)"
  task export_all: :environment do
    date = Date.current.strftime("%Y%m%d")
    output_dir = Rails.root.join("tmp", "export")
    FileUtils.mkdir_p(output_dir)
    output_path = output_dir.join("autobiography_complete_#{date}.docx")

    chapters = Chapter.all.order_chapters_with_intro_first
    user_info = {
      name: "Your Name",
      title: "My Autobiography",
      subtitle: "A Journey Through Life's Adventures",
      generated_date: Date.current.strftime("%B %d, %Y")
    }

    puts "\n📘 Generating DOCX…"
    data = DocxExporter.generate_full_docx(chapters: chapters, user_info: user_info)
    File.open(output_path, "wb") { |f| f.write(data) }
    puts "✅ Wrote: #{output_path}"
  end

  desc "Export a single chapter to DOCX. Usage: rake docx:export[ID]"
  task :export, [ :id ] => :environment do |_t, args|
    id = args[:id]&.to_i
    if id.nil? || id == 0
      abort "Usage: rake docx:export[CHAPTER_ID]"
    end

    chapter = Chapter.find_by(id: id)
    abort "Chapter not found: #{id}" unless chapter

    date = Date.current.strftime("%Y%m%d")
    output_dir = Rails.root.join("tmp", "export")
    FileUtils.mkdir_p(output_dir)
    safe_title = chapter.title.to_s.parameterize
    output_path = output_dir.join("#{safe_title}_#{date}.docx")

    user_info = {
      name: "Your Name",
      title: chapter.title,
      subtitle: chapter.subtitle.to_s,
      generated_date: Date.current.strftime("%B %d, %Y")
    }

    puts "\n📄 Generating DOCX for chapter ##{chapter.id} – #{chapter.title}…"
    data = DocxExporter.generate_full_docx(chapters: [ chapter ], user_info: user_info)
    File.open(output_path, "wb") { |f| f.write(data) }
    puts "✅ Wrote: #{output_path}"
  end
end

namespace :docx do
  desc "Export all chapters to a Narration-Ready DOCX (tmp/export/autobiography_complete_narration_YYYYMMDD.docx)"
  task export_narration_all: :environment do
    date = Date.current.strftime("%Y%m%d")
    output_dir = Rails.root.join("tmp", "export")
    FileUtils.mkdir_p(output_dir)
    output_path = output_dir.join("autobiography_complete_narration_#{date}.docx")

    chapters = Chapter.all.order_chapters_with_intro_first
    user_info = {
      name: "Your Name",
      title: "My Autobiography",
      subtitle: "A Journey Through Life's Adventures",
      generated_date: Date.current.strftime("%B %d, %Y")
    }

    puts "\n🔊 Generating Narration-Ready DOCX…"
    data = DocxExporter.generate_narration_docx(chapters: chapters, user_info: user_info)
    File.open(output_path, "wb") { |f| f.write(data) }
    puts "✅ Wrote: #{output_path}"
  end

  desc "Export a single chapter to Narration-Ready DOCX. Usage: rake docx:export_narration[ID]"
  task :export_narration, [ :id ] => :environment do |_t, args|
    id = args[:id]&.to_i
    if id.nil? || id == 0
      abort "Usage: rake docx:export_narration[CHAPTER_ID]"
    end

    chapter = Chapter.find_by(id: id)
    abort "Chapter not found: #{id}" unless chapter

    date = Date.current.strftime("%Y%m%d")
    output_dir = Rails.root.join("tmp", "export")
    FileUtils.mkdir_p(output_dir)
    safe_title = chapter.title.to_s.parameterize
    output_path = output_dir.join("#{safe_title}_narration_#{date}.docx")

    user_info = {
      name: "Your Name",
      title: chapter.title,
      subtitle: chapter.subtitle.to_s,
      generated_date: Date.current.strftime("%B %d, %Y")
    }

    puts "\n🔊 Generating Narration-Ready DOCX for chapter ##{chapter.id} – #{chapter.title}…"
    data = DocxExporter.generate_narration_docx(chapters: [ chapter ], user_info: user_info)
    File.open(output_path, "wb") { |f| f.write(data) }
    puts "✅ Wrote: #{output_path}"
  end
end

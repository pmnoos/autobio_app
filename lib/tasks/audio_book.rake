namespace :audio do
  desc "Generate TTS audio for all chapters"
  task generate_all: :environment do
    voice  = ENV["VOICE"]  || ENV["TTS_VOICE"] || "alloy"
    format = ENV["FORMAT"] || "mp3"
    model  = ENV["MODEL"]  || ENV["TTS_MODEL"] || "gpt-4o-mini-tts"
    outdir = ENV["OUTDIR"] || Rails.root.join("tmp", "audio").to_s

    unless ENV["OPENAI_API_KEY"].present?
      abort "OPENAI_API_KEY is not set. Set it in your environment before running."
    end

    FileUtils.mkdir_p(outdir)
    narrator = AudioBook::Narrator.new
    puts "Generating audio to #{outdir} (voice=#{voice}, format=#{format}, model=#{model})"

    total = 0
    errors = 0

    Chapter.order_chapters_with_intro_first.find_each do |ch|
      begin
        ext = format
        output_path = File.join(outdir, "chapter_#{ch.id}.#{ext}")
        narrator.speak(ch, output_path: output_path, voice: voice, format: format, model: model)
        puts "\u2713 Wrote #{output_path}"
        total += 1
      rescue => e
        warn "\u2717 Failed chapter #{ch.id} (#{ch.title}): #{e.message}"
        if e.message.include?("maximum input limit")
          base = File.join(outdir, "chapter_#{ch.id}.#{ext}")
          parts = narrator.speak_chunked(ch, output_base: base, voice: voice, format: format, model: model)
          puts "\u2713 Wrote #{parts.count} part(s):"
          parts.each { |p| puts "    - #{p}" }
          total += 1
        else
          errors += 1
        end
      end
    end

    puts "Done. Generated #{total} file(s), #{errors} error(s)."
    exit(errors.zero? ? 0 : 1)
  end

  desc "Generate TTS audio for a single chapter by ID"
  task :generate, [ :id ] => :environment do |t, args|
    id = args[:id] || ENV["ID"]
    abort "Please provide chapter ID: rake audio:generate[ID]" unless id.present?

    voice  = ENV["VOICE"]  || ENV["TTS_VOICE"] || "alloy"
    format = ENV["FORMAT"] || "mp3"
    model  = ENV["MODEL"]  || ENV["TTS_MODEL"] || "gpt-4o-mini-tts"
    outdir = ENV["OUTDIR"] || Rails.root.join("tmp", "audio").to_s

    unless ENV["OPENAI_API_KEY"].present?
      abort "OPENAI_API_KEY is not set. Set it in your environment before running."
    end

    FileUtils.mkdir_p(outdir)
    ch = Chapter.find(id)
    narrator = AudioBook::Narrator.new
    output_path = File.join(outdir, "chapter_#{ch.id}.#{format}")
    narrator.speak(ch, output_path: output_path, voice: voice, format: format, model: model)
    puts "\u2713 Wrote #{output_path}"
  end
end

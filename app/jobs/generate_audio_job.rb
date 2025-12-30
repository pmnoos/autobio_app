class GenerateAudioJob < ApplicationJob
  queue_as :default

  def perform(chapter_ids:, voice:, format:, model:)
    outdir = Rails.root.join("tmp", "audio").to_s
    FileUtils.mkdir_p(outdir)

    narrator = AudioBook::Narrator.new
    scope = Chapter.order_chapters_with_intro_first
    chapters = chapter_ids.present? ? scope.where(id: chapter_ids) : scope

    chapters.find_each do |ch|
      begin
        output_path = File.join(outdir, "chapter_#{ch.id}.#{format}")
        narrator.speak(ch, output_path: output_path, voice: voice, format: format, model: model)
      rescue => e
        if e.message.include?("maximum input limit")
          base = File.join(outdir, "chapter_#{ch.id}.#{format}")
          narrator.speak_chunked(ch, output_base: base, voice: voice, format: format, model: model)
        else
          Rails.logger.error("GenerateAudioJob failed for chapter ##{ch.id}: #{e.message}")
        end
      end
    end
  end
end

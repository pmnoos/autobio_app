class AudioController < ApplicationController
  protect_from_forgery with: :exception

  def index
    dir = Rails.root.join("tmp", "audio")
    files = Dir.exist?(dir) ? Dir.glob(File.join(dir, "*.mp3")) : []
    @by_chapter = files.group_by do |f|
      m = File.basename(f).match(/^chapter_(\d+)(?:_part\d+)?\.mp3$/)
      m ? m[1].to_i : :others
    end

    # Determine canonical chapter order (Dedication → Introduction → Numbered → Epilogue)
    ordered_ids = Chapter.order_chapters_with_intro_first.pluck(:id)
    order_index = {}
    ordered_ids.each_with_index { |cid, i| order_index[cid] = i }

    # Build a flattened playlist ordered by canonical chapter order then filename
    @playlist_all = []
    @by_chapter.keys.sort_by { |k| k == :others ? Float::INFINITY : (order_index[k] || Float::INFINITY) }.each do |key|
      group_files = @by_chapter[key] || []
      chapter = key == :others ? nil : Chapter.find_by(id: key)
      group_files.sort.each do |f|
        name = File.basename(f)
        @playlist_all << {
          filename: name,
          chapter_id: (chapter&.id),
          title: (chapter&.title)
        }
      end
    end
  end

  def stream
    # Accept either wildcard-captured full filename or (:filename + :format)
    filename = params[:filename].to_s
    if params[:format].present? && !filename.end_with?(".#{params[:format]}")
      filename = "#{filename}.#{params[:format]}"
    end
    safe = File.basename(filename)
    path = Rails.root.join("tmp", "audio", safe)
    unless File.exist?(path)
      head :not_found and return
    end
    send_file path, type: "audio/mpeg", disposition: "inline"
  end

  def generate
    voice  = params[:voice].presence || params[:voice_select].presence || ENV["TTS_VOICE"] || "alloy"
    format = params[:format].presence || "mp3"
    model  = params[:model].presence  || ENV["TTS_MODEL"] || "gpt-4o-mini-tts"

    chapter_ids = nil
    if params[:chapter_id].present?
      chapter_ids = [ params[:chapter_id].to_i ]
    end

    GenerateAudioJob.perform_later(chapter_ids: chapter_ids, voice: voice, format: format, model: model)
    redirect_to audio_index_path, notice: "Audio generation started in background (voice=#{voice}, format=#{format}). Refresh this page in a bit."
  end
end

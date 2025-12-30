require "action_view"
require "base64"
require "net/http"
require "json"
require "uri"
require "fileutils"

module AudioBook
  class Narrator
    include ActionView::Helpers::SanitizeHelper

    def initialize(api_key: ENV["OPENAI_API_KEY"])
      raise ArgumentError, "OpenAI API key is required" unless api_key.present?
      @api_key = api_key
    end

    # Convert chapter content to plain text for narration
    def narration_text(chapter)
      text = ActionView::Base.full_sanitizer.sanitize(chapter.content)
      "Chapter: #{chapter.title}. #{text}"
    end

    # Generate speech audio from chapter text and save to output_path
    # Uses OpenAI TTS endpoint. Supports binary or base64 JSON responses.
    def speak(chapter, output_path:, voice: ENV["TTS_VOICE"] || "alloy", format: "mp3", model: ENV["TTS_MODEL"] || "gpt-4o-mini-tts")
      text = narration_text(chapter)

      uri = URI.parse("https://api.openai.com/v1/audio/speech")
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{@api_key}"
      req["Content-Type"] = "application/json"
      req.body = {
        model: model,
        input: text,
        voice: voice,
        format: format
      }.to_json

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        resp = http.request(req)
        unless resp.is_a?(Net::HTTPSuccess)
          raise "OpenAI TTS failed: #{resp.code} #{resp.body}"
        end

        FileUtils.mkdir_p(File.dirname(output_path))

        content_type = resp["content-type"] || ""
        body = resp.body

        if content_type.include?("application/json") || body.lstrip.start_with?("{")
          json = JSON.parse(body)
          data = json["audio"] || json["data"] || json["content"]
          raise "Unexpected JSON TTS response" unless data
          audio_bytes = Base64.decode64(data)
          File.binwrite(output_path, audio_bytes)
        else
          # Assume binary audio stream
          File.binwrite(output_path, body)
        end
      end

      output_path
    end

    # Fallback: split long narration into chunks and generate multiple files
    # Returns array of part file paths
    def speak_chunked(chapter, output_base:, voice: ENV["TTS_VOICE"] || "alloy", format: "mp3", model: ENV["TTS_MODEL"] || "gpt-4o-mini-tts", max_chars: (ENV["TTS_MAX_CHARS"]&.to_i || 7000))
      full = narration_text(chapter)
      parts = []

      # Split by blank-line paragraphs, accumulate into chunks under max_chars
      paragraphs = full.split(/(?:\r?\n){2,}/)
      buf = ""
      idx = 1
      paragraphs.each do |p|
        p2 = p.strip
        next if p2.empty?
        if (buf.length + p2.length + 2) <= max_chars
          buf << (buf.empty? ? p2 : "\n\n" + p2)
        else
          # flush current buffer
          if buf.length > 0
            out = part_path(output_base, idx, format)
            speak_text(buf, out, voice: voice, format: format, model: model)
            parts << out
            idx += 1
            buf = p2
          else
            # single paragraph too large: hard split by length
            p2.scan(/.{1,#{max_chars}}/m).each do |chunk|
              out = part_path(output_base, idx, format)
              speak_text(chunk, out, voice: voice, format: format, model: model)
              parts << out
              idx += 1
            end
            buf = ""
          end
        end
      end

      if buf.length > 0
        out = part_path(output_base, idx, format)
        speak_text(buf, out, voice: voice, format: format, model: model)
        parts << out
      end

      parts
    end

    private

    def part_path(base, idx, format)
      dir = File.dirname(base)
      base_name = File.basename(base, ".#{format}")
      FileUtils.mkdir_p(dir)
      File.join(dir, "#{base_name}_part#{idx}.#{format}")
    end

    # Lower-level: speak arbitrary text to a given path
    def speak_text(text, output_path, voice:, format:, model:)
      uri = URI.parse("https://api.openai.com/v1/audio/speech")
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{@api_key}"
      req["Content-Type"] = "application/json"
      req.body = {
        model: model,
        input: text,
        voice: voice,
        format: format
      }.to_json

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        resp = http.request(req)
        unless resp.is_a?(Net::HTTPSuccess)
          raise "OpenAI TTS failed: #{resp.code} #{resp.body}"
        end
        FileUtils.mkdir_p(File.dirname(output_path))
        content_type = resp["content-type"] || ""
        body = resp.body
        if content_type.include?("application/json") || body.lstrip.start_with?("{")
          json = JSON.parse(body)
          data = json["audio"] || json["data"] || json["content"]
          raise "Unexpected JSON TTS response" unless data
          audio_bytes = Base64.decode64(data)
          File.binwrite(output_path, audio_bytes)
        else
          File.binwrite(output_path, body)
        end
      end
      output_path
    end
  end
end

namespace :audio do
  desc "Upload all MP3s from tmp/audio to Cloudinary and write a manifest + playlist"
  task upload_all: :environment do
    uploader = AudioBook::Uploader.new
    unless uploader.available?
      abort "Cloudinary not configured. Set CLOUDINARY_CLOUD_NAME and either CLOUDINARY_UPLOAD_PRESET or CLOUDINARY_API_KEY/CLOUDINARY_API_SECRET."
    end

    audio_dir = Rails.root.join("tmp", "audio")
    files = Dir.glob(audio_dir.join("**", "*.mp3").to_s)
    if files.empty?
      abort "No MP3 files found in #{audio_dir}"
    end

    output_dir = Rails.root.join("tmp", "export")
    FileUtils.mkdir_p(output_dir)
    manifest_path = output_dir.join("audio_manifest.json")
    playlist_path = output_dir.join("audio_playlist.m3u")

    manifest = []
    puts "\n☁️ Uploading #{files.size} audio files to Cloudinary…"
    files.sort.each do |path|
      basename = File.basename(path, ".mp3")
      public_id = basename
      res = uploader.upload_file(path, public_id: public_id, folder: "autobio/audio", resource_type: "video")
      puts "✓ #{basename}.mp3 → #{res[:url]}"
      manifest << { file: File.basename(path), url: res[:url], public_id: res[:public_id], bytes: res[:bytes] }
    end

    File.write(manifest_path, JSON.pretty_generate(manifest))
    File.open(playlist_path, "w") do |f|
      f.puts "#EXTM3U"
      manifest.each do |item|
        f.puts "#EXTINF:-1,#{item[:file]}"
        f.puts item[:url]
      end
    end

    puts "\n✅ Manifest: #{manifest_path}"
    puts "✅ Playlist: #{playlist_path}"
    puts "\nShare the M3U playlist or individual URLs above."
  end
end

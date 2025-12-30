# Configure Wicked PDF to find wkhtmltopdf on Windows
begin
  require "wicked_pdf"
rescue LoadError
  # Wicked PDF not loaded; skip
end

if defined?(WickedPdf)
  exe_path = ENV["WKHTMLTOPDF_PATH"].to_s.strip

  if exe_path.empty?
    begin
      # Try to use the wkhtmltopdf-binary gem's installed executable
      path = Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf")
      if Gem.win_platform? && !path.downcase.end_with?(".exe")
        candidate = File.join(File.dirname(path), "wkhtmltopdf.exe")
        path = candidate if File.exist?(candidate)
      end
      exe_path = path if File.exist?(path)
    rescue Gem::Exception
      exe_path = nil
    end
  end

  # Final fallback: allow PATH resolution if env var is set externally
  WickedPdf.config ||= {}
  WickedPdf.config[:exe_path] = exe_path if exe_path && !exe_path.empty?
end
# WickedPdf Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# renders by passing as a local hash.
#
WickedPdf.configure do |config|
  # Path to the wkhtmltopdf executable: Prefer gem binary; allow ENV override.
  begin
    resolved_path = nil

    # 1) ENV override takes priority
    env_path = ENV["WKHTMLTOPDF_PATH"]
    resolved_path = env_path if env_path.present? && File.exist?(env_path)

    # 2) Gem-provided binary (wkhtmltopdf-binary)
    if resolved_path.nil?
      begin
        gem_path = Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf")
        resolved_path = gem_path if gem_path && File.exist?(gem_path)
      rescue Gem::Exception
        # ignore
      end
    end

    # 3) Common Windows install locations
    if resolved_path.nil? && Gem.win_platform?
      common_candidates = [
        "C:/Program Files/wkhtmltopdf/bin/wkhtmltopdf.exe",
        "C:/Program Files (x86)/wkhtmltopdf/bin/wkhtmltopdf.exe"
      ]
      resolved_path = common_candidates.find { |p| File.exist?(p) }
    end

    # Apply if found
    config.exe_path = resolved_path if resolved_path.present?

    # Log outcome to help debugging in development
    begin
      if defined?(Rails) && Rails.logger
        Rails.logger.info("[WickedPdf] wkhtmltopdf exe_path: #{config.instance_variable_get(:@exe_path) || 'not set'}")
      end
    rescue => _e
      # ignore logging errors during boot
    end

  rescue Gem::Exception
    config.exe_path = ENV["WKHTMLTOPDF_PATH"].presence || "C:/Program Files/wkhtmltopdf/bin/wkhtmltopdf.exe"
  end

  # Allow local file access so images/styles can be read
  config.enable_local_file_access = true

  # Defaults that are generally safe
  config.orientation = "Portrait"
  config.page_size   = "A4"
  config.encoding    = "UTF-8"
end

module ApplicationHelper
  DEFAULT_FULL_BIO_AUDIO_URL = "https://www.dropbox.com/scl/fi/70v46kqu6kw9045by5y4e/The-Story-of-an-Ordinary-Man.mp3?rlkey=6qkedzhx5ykqpm6o7j3jyxg7x&st=hiulanhi&dl=0".freeze

  def full_bio_audio_stream_url
    normalize_dropbox_audio_url(full_bio_audio_base_url, raw: "1")
  end

  def full_bio_audio_download_url
    normalize_dropbox_audio_url(full_bio_audio_base_url, dl: "1")
  end

  private

  def full_bio_audio_base_url
    ENV["FULL_BIO_AUDIO_URL"].presence || DEFAULT_FULL_BIO_AUDIO_URL
  end

  def normalize_dropbox_audio_url(url, raw: nil, dl: nil)
    return url if url.blank?

    uri = URI.parse(url)
    return url unless uri.host.to_s.include?("dropbox.com")

    params = URI.decode_www_form(String(uri.query)).to_h
    params.delete("dl")
    params.delete("raw")
    params["raw"] = raw if raw.present?
    params["dl"] = dl if dl.present?
    uri.query = URI.encode_www_form(params)
    uri.to_s
  rescue URI::InvalidURIError
    url
  end
end

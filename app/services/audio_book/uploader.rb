require "json"

module AudioBook
  class Uploader
    def initialize(
      cloud_name: ENV["CLOUDINARY_CLOUD_NAME"],
      api_key: ENV["CLOUDINARY_API_KEY"],
      api_secret: ENV["CLOUDINARY_API_SECRET"],
      upload_preset: ENV["CLOUDINARY_UPLOAD_PRESET"]
    )
      @cloud_name = cloud_name
      @api_key = api_key
      @api_secret = api_secret
      @upload_preset = upload_preset
    end

    def available?
      @cloud_name.present? && (@upload_preset.present? || (@api_key.present? && @api_secret.present?))
    end

    # Upload a file to Cloudinary, return a hash with url/public_id
    # Uses Cloudinary gem if available; falls back to error if not configured
    def upload_file(path, folder: "autobio/audio", public_id: nil, resource_type: "video")
      raise "Cloudinary not configured" unless available?
      require "cloudinary"
      require "cloudinary/uploader"

      options = {
        folder: folder,
        resource_type: resource_type, # mp3 handled under 'video' type
        overwrite: true
      }
      options[:public_id] = public_id if public_id
      options[:upload_preset] = @upload_preset if @upload_preset.present?

      res = Cloudinary::Uploader.upload(path, **options)
      {
        url: res["secure_url"] || res["url"],
        public_id: res["public_id"],
        bytes: res["bytes"],
        format: res["format"],
        resource_type: res["resource_type"]
      }
    end
  end
end

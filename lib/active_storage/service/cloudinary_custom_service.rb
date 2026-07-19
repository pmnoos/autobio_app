# Custom Cloudinary Active Storage service.
# Replaces activestorage-cloudinary-service gem which is incompatible with
# Rails 8 and cloudinary 2.x (causes Invalid Signature on every upload).
# This service does a plain upload with no post-upload context/integrity API calls.

require "cloudinary"
require "net/http"
require "uri"

module ActiveStorage
  class Service::CloudinaryCustomService < Service
    def initialize(cloud_name:, api_key:, api_secret:, **)
      Cloudinary.config do |config|
        config.cloud_name = cloud_name.to_s.strip
        config.api_key    = api_key.to_s.strip
        config.api_secret = api_secret.to_s.strip
        config.secure     = true
      end
    end

    # Upload file — no post-upload context or integrity API call.
    def upload(key, io, checksum: nil, content_type: nil, filename: nil, **)
      instrument :upload, key: key, checksum: checksum do
        Cloudinary::Uploader.upload(
          io,
          public_id: key,
          resource_type: "auto",
          overwrite: true
        )
      end
    end

    def download(key, &block)
      url = cloudinary_url(key, resource_type: "auto")
      if block_given?
        instrument :streaming_download, key: key do
          uri = URI.parse(url)
          Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
            http.get(uri.request_uri) do |chunk|
              yield chunk.force_encoding(Encoding::BINARY)
            end
          end
        end
      else
        instrument :download, key: key do
          response = Net::HTTP.get_response(URI.parse(url))
          response.body.force_encoding(Encoding::BINARY)
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        uri = URI.parse(cloudinary_url(key, resource_type: "auto"))
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri.request_uri)
        req["Range"] = "bytes=#{range.begin}-#{range.exclude_end? ? range.end - 1 : range.end}"
        http.start { |agent| agent.request(req).body.force_encoding(Encoding::BINARY) }
      end
    end

    def delete(key)
      instrument :delete, key: key do
        # Try all resource types since we upload with resource_type: auto
        %w[image video raw].each do |type|
          Cloudinary::Uploader.destroy(key, resource_type: type) rescue nil
        end
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        Cloudinary::Api.delete_resources_by_prefix(prefix) rescue nil
      end
    end

    def exist?(key)
      instrument :exist?, key: key do
        Cloudinary::Api.resources_by_ids(key)["resources"].any?
      rescue
        false
      end
    end

    def url(key, expires_in:, disposition:, filename:, content_type:, **)
      instrument :url, key: key do
        options = {
          resource_type: resource_type_for(content_type),
          type: "upload"
        }
        options[:flags] = "attachment" if disposition.to_s == "attachment"
        cloudinary_url(key, **options)
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, **)
      instrument :url_for_direct_upload, key: key do
        cloudinary_url(key, resource_type: resource_type_for(content_type), type: "upload")
      end
    end

    def headers_for_direct_upload(key, filename:, content_type:, content_length:, checksum:, **)
      { "Content-Type" => content_type }
    end

    private

    def cloudinary_url(key, **options)
      defaults = {
        secure: true,
        sign_url: false
      }
      Cloudinary::Utils.cloudinary_url(key, **defaults.merge(options))
    end

    def resource_type_for(content_type)
      type = content_type.to_s.downcase
      return "video" if type.start_with?("audio/")
      return "video" if type.start_with?("video/")
      return "image" if type.start_with?("image/")

      "raw"
    end
  end
end

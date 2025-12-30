Cloudinary Upload Setup

1. Create a Cloudinary account
	 - Visit https://cloudinary.com and sign up.
	 - In your dashboard, note your Cloud Name.

2. Choose an auth method
	 - Easiest: Unsigned Upload Preset (no secret on server)
		 - In Cloudinary Console → Settings → Upload → Upload presets → Add upload preset.
		 - Name it (e.g., `autobio_unsigned`). Set Folder to `autobio/audio`. Allow `Unsigned` uploads.
	 - Or Signed Upload (server-side credentials)
		 - Get your API Key and API Secret from the console.

3. Set environment variables (Windows PowerShell)
	 - Unsigned upload:
		 ```powershell
		 $env:CLOUDINARY_CLOUD_NAME="your_cloud_name"
		 $env:CLOUDINARY_UPLOAD_PRESET="autobio_unsigned"
		 ```
	 - Signed upload:
		 ```powershell
		 $env:CLOUDINARY_CLOUD_NAME="your_cloud_name"
		 $env:CLOUDINARY_API_KEY="your_api_key"
		 $env:CLOUDINARY_API_SECRET="your_api_secret"
		 ```

4. Upload your audio files
	 - Ensure your MP3s exist under `tmp/audio`.
	 - Run:
		 ```powershell
		 bundle exec rake audio:upload_all
		 ```
	 - Outputs:
		 - Manifest: `tmp/export/audio_manifest.json`
		 - Playlist: `tmp/export/audio_playlist.m3u`

5. Share
	 - Send the `.m3u` playlist (opens in many players).
	 - Or share individual `secure_url` links from the manifest.

Troubleshooting
- If uploads fail: verify env vars and that the preset is `Unsigned`.
- Audio treated as `resource_type: video` so MP3s upload cleanly.


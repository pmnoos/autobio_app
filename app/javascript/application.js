// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "./narration"
import "trix"
import "@rails/actiontext"
// Keep alignment shortcuts via Stimulus; avoid toolbar injection to preserve stability
// import "./trix_alignment" // disabled
// import "./trix_alignment_toolbar" // disabled to prevent editor init issues

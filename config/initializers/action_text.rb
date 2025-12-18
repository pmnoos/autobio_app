# Configure Action Text to allow HTML links and images
Rails.application.configure do
  config.after_initialize do
    # Configure ActionText sanitizer to allow additional HTML tags and attributes
    ActionText::RichText.class_eval do
      def to_s
        # Use a custom sanitizer that allows links and images
        Rails::Html::WhiteListSanitizer.new.sanitize(
          body.to_s,
          tags: %w[
            strong b i em mark del ins sub sup
            h1 h2 h3 h4 h5 h6
            p br div span
            ul ol li
            blockquote
            a img
            figure figcaption
          ],
          attributes: %w[
            href src alt title target rel class style id
            width height
            data-filename data-filesize data-content-type
          ]
        ).html_safe
      end
    end
  end
end
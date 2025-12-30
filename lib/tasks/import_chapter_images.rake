namespace :photos do
  desc "Import chapter images (image_header and image) into Photo records"
  task import_chapter_images: :environment do
    imported = 0
    skipped = 0

    Chapter.find_each do |chapter|
      [ [ :image_header, "Header" ], [ :image, "Image" ] ].each do |attr, label|
        attachment = chapter.public_send(attr)
        next unless attachment.respond_to?(:attached?) && attachment.attached?

        # Skip if a Photo already exists for this blob
        existing = ActiveStorage::Attachment.where(
          name: "image",
          record_type: "Photo",
          blob_id: attachment.blob_id
        ).exists?

        if existing
          skipped += 1
          next
        end

        photo = Photo.new(
          title: "#{chapter.title} (#{label})",
          description: chapter.subtitle.presence,
          taken_at: chapter.created_at
        )
        # Tag as chapter-derived so gallery can filter
        photo.source = "chapter"
        photo.image.attach(attachment.blob)

        if photo.save
          imported += 1
          puts "Imported #{label.downcase} for chapter '#{chapter.title}' as photo ##{photo.id}"
        else
          skipped += 1
          puts "Skipped #{label.downcase} for chapter '#{chapter.title}': #{photo.errors.full_messages.join(', ')}"
        end
      end
    end

    puts "Import complete. Imported: #{imported}, Skipped: #{skipped}"
  end
end

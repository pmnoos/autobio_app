namespace :photos do
  desc "Flag chapter-derived photos by title suffix as source='chapter'"
  task flag_chapter_sources: :environment do
    flagged = Photo.where("title LIKE ? OR title LIKE ?", "%(Header)%", "%(Image)%")
    count = flagged.count
    updated = flagged.update_all(source: "chapter")
    puts "Flagged #{updated} photos as 'chapter' (matched #{count})."
  end
end

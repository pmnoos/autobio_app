namespace :chapters do
  desc "Backfill special_type for Dedication, Introduction, Epilogue"
  task backfill_special_type: :environment do
    # Dedication (include common misspelling)
    Chapter.where("(special_type IS NULL OR special_type = '') AND (LOWER(title) LIKE ? OR LOWER(title) LIKE ?)", "%dedication%", "%didication%")
           .update_all(special_type: "dedication")

    # Introduction
    Chapter.where("(special_type IS NULL OR special_type = '') AND LOWER(title) LIKE ?", "%intro%")
           .update_all(special_type: "introduction")

    # Epilogue
    Chapter.where("(special_type IS NULL OR special_type = '') AND LOWER(title) LIKE ?", "%epilogue%")
           .update_all(special_type: "epilogue")

    puts "Backfilled counts: #{Chapter.group(:special_type).count.inspect}"
  end
end

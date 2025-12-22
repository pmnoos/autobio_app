# Create an admin user if none exists
if User.count == 0
  admin_user = User.create!(
    email_address: "admin@autobio.com",
    password: "password123",
    password_confirmation: "password123"
  )
  puts "✅ Created admin user: admin@autobio.com with password: password123"
else
  puts "ℹ️  Users already exist in the database (#{User.count} users)"
end

# Create/import chapters if none exist or only demo placeholders exist
if Chapter.count == 0 || Chapter.count <= 2
  import_path = Rails.root.join("chapters_import.rb")
  if File.exist?(import_path)
    puts "📥 Importing chapters from #{import_path}"
    if Chapter.count > 0
      puts "🧹 Removing existing placeholder chapters"
      Chapter.delete_all
    end
    # Load the import script which creates Chapter records and sets rich text content
    load import_path

    # Backfill special_type for known sections (dedication/introduction/epilogue)
    Chapter.where("(special_type IS NULL OR special_type = '') AND (LOWER(title) LIKE ? OR LOWER(title) LIKE ?)", "%dedication%", "%didication%")
           .update_all(special_type: "dedication")
    Chapter.where("(special_type IS NULL OR special_type = '') AND LOWER(title) LIKE ?", "%intro%")
           .update_all(special_type: "introduction")
    Chapter.where("(special_type IS NULL OR special_type = '') AND LOWER(title) LIKE ?", "%epilogue%")
           .update_all(special_type: "epilogue")

    puts "✅ Imported chapters and backfilled special_type"
  else
    # Fallback: create minimal sample chapters so the app isn't empty
    intro_chapter = Chapter.create!(
      title: "Introduction",
      subtitle: "Welcome to My Story",
      content: "<p>Welcome to my autobiography. This is where your story begins...</p><p>You can edit this chapter or create new ones to tell your life story.</p>"
    )

    sample_chapter = Chapter.create!(
      title: "My Early Years",
      subtitle: "Growing Up",
      content: "<p>This is a sample chapter about your early years.</p><p>You can edit or delete this chapter and create your own content.</p><p>Use the rich text editor to format your stories with images, links, and more.</p>"
    )

    puts "✅ Created sample chapters to get you started"
  end
else
  puts "ℹ️  Chapters already exist in the database (#{Chapter.count} chapters)"
end

puts "\n🎉 Database seeded successfully!"
puts "You can now:"
puts "  • Sign up for a new account or log in with admin credentials: admin@autobio.com / password123"

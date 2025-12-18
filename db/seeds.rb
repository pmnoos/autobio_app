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

# Create some sample chapters if none exist
if Chapter.count == 0
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
else
  puts "ℹ️  Chapters already exist in the database (#{Chapter.count} chapters)"
end

puts "\n🎉 Database seeded successfully!"
puts "You can now:"
puts "  • Sign up for a new account at: http://localhost:3000/users/new"
puts "  • Or log in with admin credentials: admin@autobio.com / password123"
#!/usr/bin/env ruby

# Check for existing users and create one if needed
user_count = User.count
puts "Found #{user_count} users in the database"

if user_count == 0
  puts "No users found. Creating a default admin user..."
  user = User.create!(
    email_address: "admin@example.com",
    password: "password123"
  )
  puts "✅ Created user: #{user.email_address}"
  puts "📧 Email: admin@example.com"
  puts "🔐 Password: password123"
else
  puts "Existing users:"
  User.all.each do |user|
    puts "📧 #{user.email_address}"
  end
end

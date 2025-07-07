# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a default admin user for the autobiography app
admin_user = User.find_or_create_by(email_address: "admin@example.com") do |user|
  user.password = "password123"
end

puts "✅ Admin user created/found:"
puts "📧 Email: #{admin_user.email_address}"
puts "🔐 Password: password123"

# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

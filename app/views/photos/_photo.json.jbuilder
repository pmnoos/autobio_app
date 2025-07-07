json.extract! photo, :id, :title, :description, :taken_at, :created_at, :updated_at
json.url photo_url(photo, format: :json)

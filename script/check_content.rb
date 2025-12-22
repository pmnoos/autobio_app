# frozen_string_literal: true

# Print id, title, and content snippet/length for the first 10 ordered chapters
Chapter.order_chapters_with_intro_first.limit(10).each do |c|
  body = c.content&.body
  text = body&.to_plain_text
  puts({ id: c.id, title: c.title, length: (text ? text.length : 0), snippet: (text ? text[0, 80] : nil) }.inspect)
end

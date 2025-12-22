# frozen_string_literal: true

# Quick script to print first 10 chapters by ordering scope
puts Chapter.order_chapters_with_intro_first.limit(10)
  .map { |c| [ c.title, c.respond_to?(:special_type) ? c.special_type : nil, (c.respond_to?(:chapter_number) ? c.chapter_number : nil) ].inspect }
  .join("\n")

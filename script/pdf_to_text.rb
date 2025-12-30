#!/usr/bin/env ruby
# frozen_string_literal: true

begin
  require 'pdf-reader'
rescue LoadError
  STDERR.puts "Missing gem: pdf-reader. Install with: gem install pdf-reader"
  exit 1
end

if ARGV.length < 2
  STDERR.puts "Usage: ruby pdf_to_text.rb <input.pdf> <output.txt>"
  exit 1
end

pdf_path = ARGV[0]
out_path = ARGV[1]

unless File.exist?(pdf_path)
  STDERR.puts "Input PDF not found: #{pdf_path}"
  exit 1
end

text = +""
PDF::Reader.new(pdf_path).pages.each do |page|
  page_text = page.text.to_s
  text << page_text
  text << "\n\n"
end

File.write(out_path, text)
STDOUT.puts "Wrote text to #{out_path}"

module AudioBookHelpers
  def narration_text(chapter)
    text = ActionView::Base.full_sanitizer.sanitize(chapter.content)
    "Chapter: #{chapter.title}. #{text}"
  end
end

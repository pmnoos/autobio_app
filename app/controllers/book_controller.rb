class BookController < ApplicationController
  def show
    # Order chapters: Dedication → Introduction → numbered → Epilogue
    @chapters = Chapter.order_chapters_with_intro_first
    if pdf_available?
      @pdf_mode = true
      render pdf: "my_autobiography",
             layout: "book",
             margin: { top: 25, bottom: 25, left: 20, right: 20 },
             encoding: "UTF-8"
    else
      @pdf_mode = false
      render :show, layout: "book"
    end
  end

  private
    def pdf_available?
      begin
        config = defined?(WickedPdf) ? WickedPdf.config : {}
        exe_path = config && config[:exe_path]
        return File.exist?(exe_path) && File.executable?(exe_path) if exe_path
      rescue StandardError
        # ignore and fall back to further checks
      end

      # Try default wkhtmltopdf on PATH
      begin
        out = `wkhtmltopdf --version 2>&1`
        $?.success?
      rescue StandardError
        false
      end
    end
end

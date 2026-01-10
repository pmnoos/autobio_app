class ChaptersController < ApplicationController
  include ActionController::MimeResponds
  allow_unauthenticated_access only: [ :index, :list, :show ]
  before_action :set_chapter, only: %i[show edit update destroy export_chapter_pdf]

  # GET /chapters
  def index
    @chapters = Chapter.all.order_chapters_with_intro_first
  end

  def list
    @chapters = Chapter.all.order_chapters_with_intro_first
  end

  def show
    all_chapters = Chapter.all.order_chapters_with_intro_first
    current_index = all_chapters.find_index(@chapter)

    if current_index
      @previous_chapter = current_index > 0 ? all_chapters[current_index - 1] : nil
      @next_chapter = current_index < all_chapters.length - 1 ? all_chapters[current_index + 1] : nil
    end
  end

  # =========================
  # FULL EXPORT
  # =========================
  def export_pdf
    @chapters = Chapter.all.order_chapters_with_intro_first
    @user_info = get_user_info_for_pdf

    respond_to do |format|
      format.html

      format.pdf do
        render pdf: "autobiography_complete_#{Date.current.strftime('%Y%m%d')}",
               template: "chapters/export_pdf",
               layout: "pdf",
               page_size: "A4",
               margin: { top: 15, bottom: 15, left: 15, right: 15 },
               header: { html: { template: "shared/pdf_header" } },
               footer: { html: { template: "shared/pdf_footer" } },
               enable_local_file_access: true
      end

      # ---- DOCX EXPORT (Caracal) ----
      format.any do
        if docx_request?
          file_path = Rails.root.join(
            "tmp",
            "autobiography_complete_#{Date.current.strftime('%Y%m%d')}.docx"
          )
          docx_data = DocxExporter.generate_full_docx(chapters: @chapters, user_info: @user_info)
          File.open(file_path, "wb") { |f| f.write(docx_data) }
          send_file file_path,
                    filename: file_path.basename.to_s,
                    type: docx_mime
        end
      end
    end
  end

  # =========================
  # SINGLE CHAPTER EXPORT
  # =========================
  def export_chapter_pdf
    @user_info = get_user_info_for_pdf

    respond_to do |format|
      format.html

      format.pdf do
        html = render_to_string(template: "chapters/export_chapter_pdf", layout: false)
        pdf = Grover.new(html, format: "A4").to_pdf
        send_data pdf,
                  filename: "#{@chapter.title.parameterize}_#{Date.current.strftime('%Y%m%d')}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end

      # ---- DOCX EXPORT (Caracal) ----
      format.any do
        if docx_request?
          file_path = Rails.root.join(
            "tmp",
            "#{@chapter.title.parameterize}_#{Date.current.strftime('%Y%m%d')}.docx"
          )
          docx_data = DocxExporter.generate_full_docx(chapters: [ @chapter ], user_info: @user_info)
          File.open(file_path, "wb") { |f| f.write(docx_data) }
          send_file file_path,
                    filename: file_path.basename.to_s,
                    type: docx_mime
        end
      end
    end
  end

  # =========================
  # CRUD
  # =========================
  def new
    @chapter = Chapter.new
  end

  def edit; end

  def create
    @chapter = Chapter.new(chapter_params)

    if @chapter.save
      redirect_to chapter_path(@chapter), notice: "Chapter was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @chapter.update(chapter_params)
      if params[:download_after] == "docx"
        redirect_to export_chapter_pdf_chapter_path(@chapter, format: :docx)
      else
        redirect_to chapter_path(@chapter), notice: "Chapter was successfully updated."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chapter.destroy!
    redirect_to chapters_path, status: :see_other, notice: "Chapter was successfully destroyed."
  end

  private

  def set_chapter
    @chapter = Chapter.find(params.expect(:id))
  end

  def chapter_params
    allowed = [ :title, :subtitle, :image_header, :image, :content ]
    allowed << :special_type if Chapter.column_names.include?("special_type")
    params.expect(chapter: allowed)
  end

  def get_user_info_for_pdf
    {
      name: "Your Name",
      title: "My Autobiography",
      subtitle: "A Journey Through Life's Adventures",
      generated_date: Date.current.strftime("%B %d, %Y")
    }
  end

  # =========================
  # HELPERS
  # =========================
  def docx_request?
    requested = request.format
    (requested.respond_to?(:symbol) && requested.symbol == :docx) ||
      requested.to_s == docx_mime
  end

  def docx_mime
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  end
end

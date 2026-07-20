require "fileutils"
require "open3"
require "securerandom"

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

  # PATCH /chapters/reorder
  def reorder
    ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
    return head :unprocessable_entity if ids.empty?

    Chapter.transaction do
      ids.each_with_index do |id, index|
        Chapter.where(id: id).update_all(position: index + 1)
      end
    end

    head :ok
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
  # IMPORT DOCX
  # =========================
  def import_docx
    return unless request.post?

    upload = params[:docx_file]
    if upload.blank?
      redirect_to import_docx_chapters_path,
                  alert: "Please choose a DOCX or ODT file."
      return
    end

    extension = import_file_extension(upload.original_filename)
    unless [ ".docx", ".odt" ].include?(extension)
      redirect_to import_docx_chapters_path,
                  alert: "Unsupported file type. Please upload a DOCX or ODT file."
      return
    end

    @import_token = SecureRandom.hex(16)
    @website_chapters = ordered_chapters_for_import
    staged_path = stage_import_docx_file(upload, @import_token, extension: extension)
    importer = AudioBook::AutobiographyDocxImporter.new(staged_path)
    @preview = importer.preview_matches(database_chapters: @website_chapters)

    render :preview_docx
  rescue StandardError => e
    cleanup_staged_docx(@import_token)
    redirect_to import_docx_chapters_path,
                alert: "Could not read import file: #{e.message}"
  end

  def import_docx_apply
    token = sanitized_import_token
    if token.blank?
      redirect_to import_docx_chapters_path,
                  alert: "Import token is missing or invalid."
      return
    end

    staged_path = staged_docx_path(token)
    unless File.exist?(staged_path)
      redirect_to import_docx_chapters_path,
                  alert: "Import file could not be found. Please upload the DOCX or ODT again."
      return
    end

    importer = AudioBook::AutobiographyDocxImporter.new(staged_path)
    mappings = normalized_import_mappings
    result = if mappings.present?
      importer.import_selected!(database_chapters: ordered_chapters_for_import, mappings: mappings)
    else
      importer.import_everything!(database_chapters: ordered_chapters_for_import)
    end
    cleanup_staged_docx(token)

    notice = "Import completed: #{result[:updated]} chapter(s) updated."
    notice = "#{notice} #{result[:skipped]} chapter(s) skipped." if result.key?(:skipped)
    notice = "#{notice} #{result[:unmatched]} selection(s) did not match website chapters." if result.key?(:unmatched)

    redirect_to chapters_path,
                notice: notice
  rescue StandardError => e
    redirect_to import_docx_chapters_path,
                alert: "Import failed: #{e.message}"
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
    allowed = [ :title, :subtitle, :image_header, :image, :audio_file, :content ]
    allowed << :special_type if Chapter.column_names.include?("special_type")
    params.expect(chapter: allowed)
  end

  def get_user_info_for_pdf
    {
      name: "Your Name",
      title: "My Autobiography",
      subtitle: "A Journey Through Life's Adventures"
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

  def ordered_chapters_for_import
    Chapter.all.order_chapters_with_intro_first.to_a
  end

  def sanitized_import_token
    token = params[:import_token].to_s
    return token if token.match?(/\A[0-9a-f]{32}\z/i)

    ""
  end

  def staged_docx_path(token)
    Rails.root.join("tmp", "docx_imports", "#{token}.docx")
  end

  def staged_odt_path(token)
    Rails.root.join("tmp", "docx_imports", "#{token}.odt")
  end

  def stage_import_docx_file(upload, token, extension:)
    directory = Rails.root.join("tmp", "docx_imports")
    FileUtils.mkdir_p(directory)

    docx_path = staged_docx_path(token)
    if extension == ".docx"
      FileUtils.cp(upload.tempfile.path, docx_path)
      return docx_path
    end

    odt_path = staged_odt_path(token)
    FileUtils.cp(upload.tempfile.path, odt_path)
    convert_odt_to_docx!(odt_path, docx_path)
    docx_path
  ensure
    File.delete(odt_path) if odt_path && File.exist?(odt_path)
  end

  def cleanup_staged_docx(token)
    return if token.blank?

    path = staged_docx_path(token)
    File.delete(path) if File.exist?(path)

    odt_path = staged_odt_path(token)
    File.delete(odt_path) if File.exist?(odt_path)
  end

  def import_file_extension(filename)
    File.extname(filename.to_s).downcase
  end

  def normalized_import_mappings
    raw = params[:mappings]
    return [] if raw.blank?

    values = if raw.respond_to?(:to_unsafe_h)
      raw.to_unsafe_h.values
    else
      raw.values
    end

    values.filter_map do |entry|
      next if entry.blank?

      {
        imported_index: entry["imported_index"].to_i,
        chapter_id: entry["chapter_id"].to_i
      }
    end
  end

  def convert_odt_to_docx!(odt_path, docx_path)
    command_candidates = [
      "soffice",
      "soffice.com",
      "C:/Program Files/LibreOffice/program/soffice.exe",
      "C:/Program Files/LibreOffice/program/soffice.com"
    ]

    conversion_output = []
    command_candidates.each do |command|
      stdout_str, stderr_str, status = Open3.capture3(
        command,
        "--headless",
        "--convert-to",
        "docx",
        "--outdir",
        odt_path.dirname.to_s,
        odt_path.to_s
      )
      conversion_output << [ command, stdout_str, stderr_str ]
      return if status.success? && File.exist?(docx_path)
    rescue Errno::ENOENT
      next
    end

    details = conversion_output.filter_map do |command, stdout_str, stderr_str|
      output = [ stdout_str, stderr_str ].join(" ").strip
      next if output.blank?

      "#{command}: #{output}"
    end.join(" | ")

    message = "ODT conversion failed. Install LibreOffice and ensure 'soffice' is available in PATH."
    message = "#{message} #{details}" if details.present?
    raise ArgumentError, message
  end
end

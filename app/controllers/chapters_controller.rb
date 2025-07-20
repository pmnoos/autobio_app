class ChaptersController < ApplicationController
  include ActionController::MimeResponds
  allow_unauthenticated_access only: [:index, :list, :show, :export_pdf, :export_chapter_pdf]
  before_action :set_chapter, only: %i[ show edit update destroy export_chapter_pdf ]

  # GET /chapters or /chapters.json
  def index
    @chapters = Chapter.all.order_chapters_with_intro_first
  end

  # GET /chapters/list
  def list
    @chapters = Chapter.all.order_chapters_with_intro_first
  end

  # GET /chapters/1 or /chapters/1.json
  def show
  end

  # GET /chapters/export_pdf
  def export_pdf
    @chapters = Chapter.all.order_chapters_with_intro_first
    @user_info = get_user_info_for_pdf
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "autobiography_complete_#{Date.current.strftime('%Y%m%d')}",
               template: 'chapters/export_pdf',
               layout: 'pdf',
               page_size: 'A4',
               margin: {
                 top: 15,
                 bottom: 15,
                 left: 15,
                 right: 15
               },
               header: {
                 html: {
                   template: 'shared/pdf_header'
                 }
               },
               footer: {
                 html: {
                   template: 'shared/pdf_footer'
                 }
               },
               enable_local_file_access: true
      end
    end
  end

  # GET /chapters/1/export_chapter_pdf
  def export_chapter_pdf
    @user_info = get_user_info_for_pdf
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "#{@chapter.title.parameterize}_#{Date.current.strftime('%Y%m%d')}",
               template: 'chapters/export_chapter_pdf',
               layout: 'pdf',
               page_size: 'A4',
               margin: {
                 top: 15,
                 bottom: 15,
                 left: 15,
                 right: 15
               },
               header: {
                 html: {
                   template: 'shared/pdf_header'
                 }
               },
               footer: {
                 html: {
                   template: 'shared/pdf_footer'
                 }
               },
               enable_local_file_access: true
      end
    end
  end

  # GET /chapters/new
  def new
    @chapter = Chapter.new
  end

  # GET /chapters/1/edit
  def edit
  end

  # POST /chapters or /chapters.json
  def create
    @chapter = Chapter.new(chapter_params)

    respond_to do |format|
      if @chapter.save
        format.html { redirect_to @chapter, notice: "Chapter was successfully created." }
        format.json { render :show, status: :created, location: @chapter }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chapter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chapters/1 or /chapters/1.json
  def update
    respond_to do |format|
      if @chapter.update(chapter_params)
        format.html { redirect_to @chapter, notice: "Chapter was successfully updated." }
        format.json { render :show, status: :ok, location: @chapter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chapter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chapters/1 or /chapters/1.json
  def destroy
    @chapter.destroy!

    respond_to do |format|
      format.html { redirect_to chapters_path, status: :see_other, notice: "Chapter was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chapter
      @chapter = Chapter.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def chapter_params
      params.expect(chapter: [ :title, :subtitle, :image_header, :content ])
    end

    # Get user information for PDF export
    def get_user_info_for_pdf
      {
        name: "Your Name", # Replace with actual user name from User model
        title: "My Autobiography",
        subtitle: "A Journey Through Life's Adventures",
        generated_date: Date.current.strftime("%B %d, %Y")
      }
    end
end

  # GET /photos/1/pdf
  def pdf
    @photo = Photo.find(params[:id])
    html = render_to_string(template: "photos/show", layout: false)
    pdf = Grover.new(html, format: "A4").to_pdf
    send_data pdf, filename: "photo-#{@photo.id}.pdf", type: "application/pdf", disposition: "attachment"
  end
class PhotosController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]
  before_action :set_photo, only: %i[ show edit update destroy ]
  # GET /photos or /photos.json
  def index
    # Preload attachments to avoid N+1 and ensure robust rendering
    @photos = Photo.by_position.with_attached_image
    # Exclude chapter-derived images using `source` flag
    @photos = @photos.where.not(source: "chapter")
  end

  # PATCH /photos/reorder
  def reorder
    ids = Array(params[:ids])
    ids.each_with_index do |id, index|
      Photo.where(id: id.to_i).update_all(position: index + 1)
    end
    head :ok
  end

  # GET /photos/bulk_upload
  def bulk_upload
  end

  # POST /photos/bulk_upload
  def bulk_upload_save
    files = Array(params[:images]).select { |f| f.respond_to?(:original_filename) }

    if files.empty?
      redirect_to bulk_upload_photos_path, alert: "No photos selected." and return
    end

    # Cap at 10 per request to avoid Render's 30s timeout
    files = files.first(10)

    imported = 0
    errors   = 0

    files.each do |file|
      title = File.basename(file.original_filename, ".*")
                  .gsub(/[_\-]+/, " ")
                  .split.map(&:capitalize).join(" ")

      photo = Photo.new(title: title)
      photo.image.attach(
        io:           file,
        filename:     file.original_filename,
        content_type: file.content_type
      )

      if photo.save
        imported += 1
      else
        errors += 1
      end
    end

    redirect_to photos_path, notice: "Imported #{imported} photo(s).#{errors > 0 ? " #{errors} failed." : ""}"
  end

  # GET /photos/1 or /photos/1.json
  def show
  end

  # GET /chapters/:chapter_id/photos/:id
  def show_from_chapter
    @chapter_id = params[:chapter_id]
    @photo = Photo.find(params[:id])
    # Redirect to regular photo show with chapter parameter
    redirect_to photo_path(@photo, chapter_id: @chapter_id)
  end

  # GET /photos/new
  def new
    @photo = Photo.new
  end

  # GET /photos/1/edit
  def edit
  end

  # POST /photos or /photos.json
  def create
    @photo = Photo.new(photo_params)

    respond_to do |format|
      if @photo.save
        format.html { redirect_to @photo, notice: "Photo was successfully created." }
        format.json { render :show, status: :created, location: @photo }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /photos/1 or /photos/1.json
  def update
    respond_to do |format|
      if @photo.update(photo_params)
        format.html { redirect_to @photo, notice: "Photo was successfully updated." }
        format.json { render :show, status: :ok, location: @photo }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /photos/1 or /photos/1.json
  def destroy
    @photo.destroy!

    respond_to do |format|
      format.html { redirect_to photos_path, status: :see_other, notice: "Photo was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_photo
      @photo = Photo.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def photo_params
      params.expect(photo: [ :title, :description, :taken_at, :image, :position ])
    end
end

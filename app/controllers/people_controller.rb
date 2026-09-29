class PeopleController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  before_action :set_person, only: [ :edit, :update, :destroy ]

  def show
    @person = Person.find(params[:id])
    @parents  = @person.parents
    @spouses  = @person.spouses
    @children = @person.children
    @siblings = @person.siblings
  end

  def new
    @person = Person.new
    @related_to = Person.find_by(id: params[:related_to])
  end

  def create
    if params[:existing_person_id].present?
      @person = Person.find(params[:existing_person_id])
      relationship_description = link_new_relationship
      redirect_to @person, notice: "Linked #{@person.full_name}#{relationship_description}."
      return
    end

    @person = Person.new(person_params)

    if @person.save
      relationship_description = link_new_relationship
      redirect_to @person, notice: "#{@person.full_name} was added#{relationship_description}."
    else
      @related_to = Person.find_by(id: params[:related_to])
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @person.update(person_params)
      redirect_to @person, notice: "Person was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @person.destroy
    redirect_to root_path, notice: "Person was successfully removed."
  end

  private

  def set_person
    @person = Person.find(params[:id])
  end

 def link_new_relationship
  return "" if params[:related_to].blank? || params[:relationship_kind].blank?

  related_to = Person.find(params[:related_to])
  dates = { start_date: params[:relationship_start_date].presence, end_date: params[:relationship_end_date].presence }

  label = case params[:relationship_kind]
  when "parent_of_related"
    Relationship.find_or_create_by!(person: @person, related_person: related_to, relationship_type: :parent).update!(dates)
    "parent"
  when "child_of_related"
    Relationship.find_or_create_by!(person: related_to, related_person: @person, relationship_type: :parent).update!(dates)
    related_to.spouses.each do |spouse|
      Relationship.find_or_create_by!(person: spouse, related_person: @person, relationship_type: :parent)
    end
    "child"
  when "step_parent_of_related"
    Relationship.find_or_create_by!(person: @person, related_person: related_to, relationship_type: :parent, notes: "step")
    "step-parent"
  when "step_child_of_related"
    Relationship.find_or_create_by!(person: related_to, related_person: @person, relationship_type: :parent, notes: "step")
    "step-child"
  when "spouse_of_related"
    Relationship.find_or_create_by!(person: related_to, related_person: @person, relationship_type: :spouse).update!(dates)
    "spouse"
  when "sibling_of_related"
    Relationship.find_or_create_by!(person: related_to, related_person: @person, relationship_type: :sibling)
    "sibling"
  end

  " as #{related_to.full_name}'s #{label}"
end

  def person_params
  params.require(:person).permit(:first_name, :last_name, :maiden_name,
                                  :birth_date, :death_date, :birth_place,
                                  :death_place, :gender, :bio_notes, :is_self, :photo)
  end
end

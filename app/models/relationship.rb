class Relationship < ApplicationRecord
  belongs_to :person
  belongs_to :related_person, class_name: "Person"

  enum :relationship_type, { parent: 0, spouse: 1, sibling: 2 }

  validate :person_and_related_person_are_different

  private

  def person_and_related_person_are_different
    if person_id.present? && person_id == related_person_id
      errors.add(:related_person, "can't be the same person")
    end
  end
end
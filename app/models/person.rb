class Person < ApplicationRecord
  has_many :relationships_as_subject, class_name: "Relationship", foreign_key: :person_id, dependent: :destroy
  has_many :relationships_as_related, class_name: "Relationship", foreign_key: :related_person_id, dependent: :destroy
  has_one_attached :photo

  validates :first_name, presence: true
  def self.me
    find_by(is_self: true)
  end

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  before_save :clear_other_is_self, if: :is_self?

# Convention: a Relationship(person: A, related_person: B, relationship_type: :parent) means "A is a parent of B".
def parents
  Person.where(id: relationships_as_related.where(relationship_type: :parent).select(:person_id)).order(:birth_date)
end

def children
  Person.where(id: relationships_as_subject.where(relationship_type: :parent).select(:related_person_id)).order(:birth_date)
end

  def spouses
    subject_ids = relationships_as_subject.spouse.pluck(:related_person_id)
    related_ids = relationships_as_related.spouse.pluck(:person_id)
    Person.where(id: subject_ids + related_ids)
  end

  def spouse_relationships
    subject_rows = relationships_as_subject.where(relationship_type: :spouse).map do |relationship|
      { person: relationship.related_person, start_date: relationship.start_date, end_date: relationship.end_date }
    end
    related_rows = relationships_as_related.where(relationship_type: :spouse).map do |relationship|
      { person: relationship.person, start_date: relationship.start_date, end_date: relationship.end_date }
    end

    subject_rows + related_rows
  end

def siblings
  from_shared_parents = parents.flat_map(&:children) - [self]

  explicit_subject = relationships_as_subject.where(relationship_type: :sibling).map(&:related_person)
  explicit_related = relationships_as_related.where(relationship_type: :sibling).map(&:person)

  (from_shared_parents + explicit_subject + explicit_related).uniq.sort_by { |p| p.birth_date || Date::Infinity.new }
end

  private

  def clear_other_is_self
    Person.where.not(id: id).update_all(is_self: false)
  end
end

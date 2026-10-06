class FamilyTreeController < ApplicationController
  # Public, like the person pages. Remove this line to require sign-in.
  allow_unauthenticated_access only: [ :show ]

  def show
    @tree_data = build_tree_data
    @main_id = (Person.me || Person.order(:birth_date).first)&.id
  end

  private

  # Turns Person and Relationship records into the format family-chart expects.
  # Convention: Relationship(person: A, related_person: B, type: parent) = "A is a parent of B".
  def build_tree_data
    links = Hash.new { |hash, key| hash[key] = { parents: [], spouses: [], children: [] } }

    Relationship.all.each do |rel|
      # Step-parents are left out for now: the chart allows only two parents per person.
      next if rel.notes.to_s.strip.downcase == "step"

      a = rel.person_id.to_s
      b = rel.related_person_id.to_s

      case rel.relationship_type
      when "parent"
        links[a][:children] |= [ b ]
        links[b][:parents]  |= [ a ]
      when "spouse"
        links[a][:spouses] |= [ b ]
        links[b][:spouses] |= [ a ]
      end
    end

    Person.all.map do |person|
      {
        id: person.id.to_s,
        data: {
          "first name" => person.first_name.to_s,
          "last name" => person.last_name.to_s,
          "years" => years_for(person),
          "page" => page_link_for(person),
          "gender" => person.gender.to_s.downcase.start_with?("f") ? "F" : "M"
        },
        rels: links[person.id.to_s]
      }
    end
  end

  def years_for(person)
    born = person.birth_date&.year
    died = person.death_date&.year
    return "" if born.nil? && died.nil?
    return "b. #{born}" if died.nil?

    "#{born || '?'} – #{died}"
  end

  # A small link shown on each card that opens that person's own page.
  def page_link_for(person)
    "<a href=\"#{person_path(person)}\" data-turbo=\"false\" style=\"color:#9ecbff;text-decoration:underline;\">View page</a>"
  end
end
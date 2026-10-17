class FamilyTreeController < ApplicationController
  # Public, like the person pages. Remove this line to require sign-in.
  allow_unauthenticated_access only: [ :show ]

  def show
    @skipped_links = []
    @tree_data = build_tree_data
    @main_id = (Person.me || Person.order(:birth_date).first)&.id
  end

  private

  # Turns Person and Relationship records into the format family-chart expects.
  # Convention: Relationship(person: A, related_person: B, type: parent) = "A is a parent of B".
  def build_tree_data
    links = Hash.new { |hash, key| hash[key] = { parents: [], spouses: [], children: [] } }
    people_by_id = Person.pluck(:id, :first_name, :last_name).to_h { |id, f, l| [ id.to_s, [ f, l ].compact_blank.join(" ") ] }

    Relationship.order(:id).each do |rel|
      # Step-parents are left out for now: the chart allows only two parents per person.
      next if rel.notes.to_s.strip.downcase == "step"

      a = rel.person_id.to_s
      b = rel.related_person_id.to_s
      next unless people_by_id.key?(a) && people_by_id.key?(b)

      case rel.relationship_type
      when "parent"
        problem = parent_link_problem(links, a, b)
        if problem
          skip_link("#{people_by_id[a]} as parent of #{people_by_id[b]}", problem)
        else
          links[a][:children] |= [ b ]
          links[b][:parents]  |= [ a ]
        end
      when "spouse"
        if a == b || links[a][:parents].include?(b) || links[a][:children].include?(b)
          skip_link("#{people_by_id[a]} as spouse of #{people_by_id[b]}", "they are also parent and child")
        else
          links[a][:spouses] |= [ b ]
          links[b][:spouses] |= [ a ]
        end
      end
    end

    signed_in = authenticated?

    Person.with_attached_photo.map do |person|
      hidden = person.private_profile? && !signed_in
      {
        id: person.id.to_s,
        data: {
          "first name" => person.first_name.to_s,
          "last name" => person.last_name.to_s,
          "years" => hidden ? "" : years_for(person),
          "page" => page_link_for(person),
          "avatar" => hidden ? nil : avatar_for(person),
          "gender" => person.gender.to_s.downcase.start_with?("f") ? "F" : "M"
        },
        rels: links[person.id.to_s]
      }
    end
  end

  # Returns a short reason if adding "a is a parent of b" would break the chart, otherwise nil.
  def parent_link_problem(links, a, b)
    return "a person cannot be their own parent" if a == b
    return "they would have more than two parents" if !links[b][:parents].include?(a) && links[b][:parents].size >= 2
    return "it would make a person their own ancestor" if descendant?(links, b, a)
    return "a parent is also a child or spouse of the same person" if links[a][:spouses].include?(b)

    nil
  end

  # True when `target` can be reached by following child links down from `start`.
  def descendant?(links, start, target)
    seen = {}
    stack = [ start ]
    until stack.empty?
      current = stack.pop
      next if seen[current]

      seen[current] = true
      return true if current == target

      stack.concat(links[current][:children])
    end
    false
  end

  def skip_link(description, reason)
    @skipped_links << "#{description} (#{reason})"
    Rails.logger.warn("[family tree] Skipped link: #{description} - #{reason}")
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
    "<a href=\"#{person_path(person)}\" data-turbo=\"false\" style=\"color:#1a56a0;text-decoration:underline;font-size:15px;\">View page</a>"
  end

  # Address of the person's attached photo, or nil when there isn't one.
  def avatar_for(person)
    person.photo.attached? ? rails_blob_path(person.photo, only_path: true) : nil
  end
end
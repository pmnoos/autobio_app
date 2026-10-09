class SuggestionMailer < ApplicationMailer
  def suggestion_email(person:, name:, email:, message:)
    @person = person
    @name = name
    @email = email
    @message = message

    mail(
      to: "petermagner3@gmail.com",
      subject: "Family tree suggestion: #{person.full_name}",
      reply_to: email.presence
    )
  end
end

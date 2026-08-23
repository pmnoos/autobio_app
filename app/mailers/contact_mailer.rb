class ContactMailer < ApplicationMailer
  def contact_email(name:, email:, subject:, message:)
    @name = name
    @email = email
    @subject = subject
    @message = message

    mail(
      to: "petermagner3@gmail.com",
      subject: "Website Contact: #{@subject}",
      reply_to: email
    )
  end
end
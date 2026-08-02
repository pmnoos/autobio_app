class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :about, :privacy, :terms, :contact, :send_contact ]

  def about
  end

  def privacy
  end

  def terms
  end

  def contact
  end

  def send_contact
    Resend.api_key = ENV["RESEND_API_KEY"]

    Resend::Emails.send({
      "from" => "My Autobiography <noreply@petermagner.com>",
      "to" => [ "petermagner3@gmail.com" ],
      "reply_to" => params[:email],
      "subject" => "New contact form message: #{params[:subject]}",
      "html" => <<~HTML
        <p><strong>Name:</strong> #{params[:name]}</p>
        <p><strong>Email:</strong> #{params[:email]}</p>
        <p><strong>Subject:</strong> #{params[:subject]}</p>
        <p><strong>Message:</strong></p>
        <p>#{params[:message]}</p>
      HTML
    })

    redirect_to contact_path, notice: "Thanks for your message — I'll get back to you soon."
  rescue StandardError => e
    Rails.logger.error("Contact form email failed: #{e.class} - #{e.message}")
    redirect_to contact_path, alert: "Sorry, something went wrong sending your message. Please try again or email directly."
  end
end
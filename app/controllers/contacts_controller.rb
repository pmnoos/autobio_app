class ContactsController < ApplicationController
  allow_unauthenticated_access only: [:create]

  def create
    ContactMailer.contact_email(
      name: params[:name],
      email: params[:email],
      subject: params[:subject],
      message: params[:message]
    ).deliver_now

    redirect_to contact_path,
                notice: "Thank you! Your message has been sent successfully."
  end
end
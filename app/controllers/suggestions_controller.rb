class SuggestionsController < ApplicationController
  allow_unauthenticated_access only: [ :create ]
  rate_limit to: 5, within: 10.minutes, only: :create,
             with: -> { redirect_to root_path, alert: "Too many messages. Please try again later." }

  def create
    person = Person.find(params[:person_id])

    # A hidden field real visitors leave empty. If it is filled in, it is a bot.
    if params[:website].present?
      redirect_to person_path(person), notice: "Thank you! Your note has been sent."
      return
    end

    if params[:message].to_s.strip.blank?
      redirect_to person_path(person), alert: "Please write a note first."
      return
    end

    SuggestionMailer.suggestion_email(
      person: person,
      name: params[:name].to_s.strip.first(100),
      email: params[:email].to_s.strip.first(150),
      message: params[:message].to_s.first(2000)
    ).deliver_now

    redirect_to person_path(person), notice: "Thank you! Your note has been sent."
  end
end

class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  # Sign-up is closed. Accounts are created by the site owner only.
  def new
    redirect_to root_path, alert: "Sign-up is closed."
  end

  def create
    redirect_to root_path, alert: "Sign-up is closed."
  end
end

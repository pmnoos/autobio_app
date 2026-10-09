class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :admin?

  private

  # True only for a signed-in account with the admin flag switched on.
  def admin?
    authenticated? && Current.user&.admin? == true
  end

  # Use as: before_action :require_admin, only: [ ... ]
  # Visitors who aren't signed in are sent to sign-in first by the existing check.
  def require_admin
    return if admin?
    redirect_to root_path, alert: "Only the site owner can do that."
  end
end

class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :about, :privacy, :terms, :contact ]

  def about
  end

  def privacy
  end

  def terms
  end

  def contact
  end
end
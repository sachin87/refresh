class PagesController < ApplicationController
  def home
  end

  def store
  end

  def notifications
  end

  def landing
    @cities = Address.for_stores.select(:city_id).distinct.map(&:city).map(&:name)
  end

  def account
  end

  def help
  end

  def about
  end

  def terms
  end

  def blog
  end

  def privacy
  end

  def contact
  end

  def partners
  end

  def forgot
  end

  def register
  end

  def search
  end

end

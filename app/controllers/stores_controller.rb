class StoresController < ApplicationController
  def search_by_address
    session[:coordinates] = [params[:latitude], params[:longitude]]

    search_by_city
  end

  def search_by_city
    @city = city
    @stores = stores_in(@city)
    render :index
  end

  def show
    # We order by distance here to expose the distance method,
    # since the distance to the user is calculated via query.
    @store = try_to_order_by_distance(Store.all).friendly.find(params[:id])
  end

  private

  def try_to_order_by_distance(scope)
    if session[:coordinates]
      scope.order_by_distance(session[:coordinates])
    else
      scope
    end
  end

  def stores_in(city)
    try_to_order_by_distance Store.by_city(city)
  end

  def city
    params[:city].titleize
  end
end
class StoreSearcher
  def initialize(options)
    self.city        = options.fetch(:city, nil)
    self.coordinates = options.fetch(:coordinates, nil)
  end

  def all
    stores_in(city).joins(chain: :clothes).uniq
  end

  def available_for_delivery
    coordinates.blank? ? Store.none : Store.available_for_delivery(coordinates)
  end

  # We order by distance here to expose the distance method,
  # since the distance to the user is calculated via query.
  def find(id)
    store = Store.friendly.find(id)
    store.set_distance_from_user!(coordinates)
    store
  end

  private

    attr_accessor :city, :coordinates

    def try_to_order_by_distance(scope)
      if coordinates.present?
        scope.order_by_distance(coordinates)
      else
        scope
      end
    end

    def stores_in(city)
      try_to_order_by_distance Store.by_city(city)
    end
end

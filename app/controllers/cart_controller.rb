class CartController < ApplicationController
  def index
    @cart = cart
    @cart_items = @cart.shopping_cart_items.order(:created_at)
  end

  def add
    authorize product.store
    @product = product
    Cart.transaction do
      cart.add(product, product.price, quantity)
    end

    respond_to do |format|
      format.json { head :ok }
      format.html do
        render layout: false
      end
    end
  end

  def remove
    cart.remove(product, cart.item_for(product).quantity)

    respond_to do |format|     
      format.json { head :ok }
      format.html do
        render layout: false
      end
    end
  end

  def remove_one
    @product = product
    new_quantity = cart.item_for(product).quantity - 1
    if new_quantity > -1
      cart.item_for(product).update!(quantity: new_quantity)
    end

    respond_to do |format|
      format.js
      format.json { head :ok }
      format.html do
        render layout: false
      end
    end
  end

  def update
    cart.item_for(product).update!(quantity: quantity)

    respond_to do |format|
      format.json { head :ok }
      format.html do
        render layout: false
      end
    end
  end

  private

    def quantity
      params.require(:quantity).to_i
    end

    def product
      @product ||= Product.find(params[:product_id])
    end
end

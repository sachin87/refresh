class OrdersController < ApplicationController
  before_filter :authenticate_user!

  def index
    @orders = current_user.orders.order(created_at: :desc)
  end

  def new
    @cart = cart
    @cart.delivery_time = params.require(:delivery_time).to_i
    @order = Order.new
    if @cart.empty?
      flash[:info] = 'Your cart is empty, cannot checkout yet.'
      redirect_to root_path
    end
  end

  def create
    cart.delivery_time = order_params[:delivery_time].to_i
    order = Order.create!(order_params) do |order|
      order.user = current_user
      order.amount = cart.total
      order.status = 'pending'
    end

    begin
      MakePayment.new(order: order, cart: cart, stripe_token: stripe_token).pay
      flash[:success] = "Checkout was successful! Waiting confirmation..."
    rescue ActiveRecord::RecordInvalid
      order.internal_failure!
      flash[:danger] = "Something went wrong. Contact us and we'll solve the problem."
    rescue Stripe::StripeError => e
      order.external_failure!
      flash[:danger] = e.message
    end
    redirect_to root_path
  end

  private

    def order_params
      params.require(:order).permit(:delivery_time, :delivery_address, :observations, :source_id)
    end

    def stripe_token
      params[:stripeToken]
    end
end

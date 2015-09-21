class OrdersController < ApplicationController
  before_filter :authenticate_user!

  def index
    @orders = current_user.orders.order(created_at: :desc)
  end

  def new
    @cart = cart
  end

  def create
    order = Order.create!(
      user: current_user,
      amount: cart.total,
      status: 'pending'
    )

    begin
      Order.transaction do
        order.update!(cart_items: cart.shopping_cart_items)
        cart.destroy!

        customer = Stripe::Customer.create(
          card: params[:stripeToken],
          description: 'Paying user',
          email: current_user.email
        )

        current_user.update!(customer_id: customer.id)

        Stripe::Charge.create(
          :amount   => order.amount_cents,
          :currency => "usd",
          :customer => current_user.customer_id
        )

        order.waiting_confirmation!
        flash[:success] = "Checkout was successful! Waiting confirmation..."
      end
    rescue ActiveRecord::RecordInvalid
      order.internal_failure!
      flash[:danger] = "Something went wrong. Contact us and we'll solve the problem."
    rescue Stripe::StripeError => e
      order.external_failure!
      flash[:danger] = e.message
    end
    redirect_to root_path
  end
end

class MakePayment
  def initialize(options)
    self.order = options.fetch(:order)
    self.cart = options.fetch(:cart)
    self.stripe_token = options.fetch(:stripe_token)
  end

  def pay
    Order.transaction do
      order.update!(cart_items: cart.shopping_cart_items)
      cart.reload.destroy!

      if stripe_token.present? && order.source_id.blank?
        if user.customer_id.present?
          # Register a new credit card for existing customer
          customer = Stripe::Customer.retrieve(user.customer_id)
          customer.sources.create(source: stripe_token)
        else
          customer = Stripe::Customer.create(
            card: stripe_token,
            description: 'Paying user',
            email: user.email)

          user.update!(customer_id: customer.id)
        end
      end

      order.update!(charge_id: charge.id)
      order.waiting_confirmation!
    end
  end

  private

    attr_accessor :order, :cart, :stripe_token
    delegate :user, to: :order

    def charge
      charge_params = {
        amount: order.amount_cents,
        currency: 'usd',
        customer: user.customer_id}

        charge_params[:source] = order.source_id if order.source_id.present?

      @charge ||= Stripe::Charge.create(charge_params)
    end
end

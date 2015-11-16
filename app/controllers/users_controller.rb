class UsersController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      flash[:success] = "Profile updated with success!"
      redirect_to root_path
    else
      flash[:danger] = current_user.errors.full_messages.join(', ')
      render :edit
    end
  end

  def add_credit_card
    respond_to do |format|
      format.json do
        begin
          customer.sources.create(source: params[:credit_card].merge(object: 'card'))
          partial_html = render_to_string(partial: 'pages/account/credit_cards', locals: {message: 'Card added!'})
          render json: {html: partial_html}
        rescue Stripe::CardError => e
          @credit_card = CreditCard.new params[:credit_card]
          @credit_card.errors.add(:base, e.message)
          partial_html = render_to_string(partial: 'pages/account/credit_cards', locals: {message: e.message})
          render json: {html: partial_html}, status: :unprocessable_entity
        end
      end
    end
  end

  def remove_credit_card
    customer.sources.retrieve(params[:credit_card_id]).delete()
    flash[:success] = 'Credit card removed.'
    redirect_to :back
  end

  private

    def user_params
      params.require(:user).permit(
        addresses_attributes: [:id, :address, :city_id, :_destroy]
      )
    end

    def customer
      if current_user.customer_id.present?
        customer = Stripe::Customer.retrieve(current_user.customer_id)
      else
        customer = Stripe::Customer.create(email: current_user.email)
        update!(customer_id: customer.id)
      end

      customer
    end
end

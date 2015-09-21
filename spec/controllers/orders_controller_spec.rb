require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let(:user) { create(:user, customer_id: 1) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET #index" do
    let!(:order) { create(:order, user: user) }
    let!(:another_user_order) { create(:order) }

    def do_action
      get :index
    end

    context "authenticated" do
      before do
        sign_in user
      end

      it "returns all the orders for the user" do
        do_action
        expect(assigns[:orders]).to eq [order]
      end
    end

    context "unauthenticated" do
      it "should redirect the user to the sign in page" do
        do_action
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  describe "GET #new" do
    def do_action
      get :new
    end

    describe "authenticated" do
      let(:cart) { Cart.create! }

      before do
        session[:cart_id] = cart.id
        sign_in user
      end

      it "sets the cart for the user" do
        do_action
        expect(assigns[:cart]).to eq cart
      end
    end
  end

  describe "POST #create" do
    def do_action
      post :create
    end

    context "authenticated" do
      let!(:cart) { Cart.create! }
      let!(:cart_items) { 2.times.map { cart.add(create(:cloth_instance), 1) } }

      before do
        session[:cart_id] = cart.id
        sign_in user
        allow(Stripe::Charge).to receive(:create).with(
          :amount   => cart.total.cents,
          :currency => "usd",
          :customer => user.customer_id
        )
      end

      it "creates a new order from the cart" do
        expect {
          do_action
        }.to change(Order, :count).by(1)
      end

      describe "post-conditions" do
        before do
          do_action
        end

        def order
          Order.last
        end

        it { expect(order.cart_items).to eq cart_items }
        it { expect(order.user).to eq user }
        it { expect(order.amount).to eq cart.total }
        it { expect(Cart.exists? cart.id).to be false }
        it { expect(Stripe::Charge).to have_received(:create) }

        it "redirects to root path" do
          expect(response).to redirect_to root_path
        end

        it "sets a success message" do
          expect(flash[:success]).to eq "Checkout was successful!"
        end
      end
    end

    context "unauthenticated" do
      it "should redirect the user to the sign in page" do
        do_action
        expect(response).to redirect_to new_user_session_path
      end
    end
  end
end

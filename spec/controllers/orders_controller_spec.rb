require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let(:user) { create(:user) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET #index" do
    let!(:old_order) { create(:order, user: user, created_at: 2.days.ago) }
    let!(:new_order) { create(:order, user: user) }
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
        expect(assigns[:orders]).to eq [new_order, old_order]
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
    let(:delivery_time) { 1 }

    def do_action
      get :new, delivery_time: delivery_time
    end

    describe "authenticated" do
      let(:cart) { Cart.create! }

      before do
        cart.add(create(:product), 1)
        session[:cart_id] = cart.id
        sign_in user
      end

      it "sets the cart for the user" do
        do_action
        expect(assigns[:cart]).to eq cart
        expect(assigns[:cart].delivery_time).to eq delivery_time
      end

      it "renders the correct page" do
        expect(do_action).to render_template 'orders/new'
      end

      context "cart is empty" do
        before do
          cart.clear
        end

        it "redirects the user to the root page" do
          do_action
          expect(response).to redirect_to root_path
        end

        it "sets a message" do
          do_action
          expect(flash[:info]).to eq 'Your cart is empty, cannot checkout yet.'
        end
      end
    end
  end

  describe "POST #create" do
    let(:token) { 'some token' }
    let(:customer_double) { double('Stripe::Customer', id: 'some customer id') }
    let(:charge_double) { double('Stripe::Charge', id: 'some charge id') }
    let(:delivery_time) { 1 }
    let(:delivery_address) { "18th Street Atlanta" }

    def do_action
      post :create, stripeToken: token, order: {
        delivery_time: delivery_time,
        delivery_address: delivery_address,
        observations: 'Take off the bacon!' }
    end

    def order
      Order.last
    end

    context "authenticated" do
      let!(:cart) { Cart.create! }
      let!(:cart_items) { 2.times.map { cart.add(create(:product), 1) } }
      let(:total_cost) { cart.subtotal }

      before do
        session[:cart_id] = cart.id
        sign_in user

        allow(Stripe::Customer).to receive(:create).with(
          card:        token,
          description: 'Paying user',
          email:       user.email
        ).and_return(customer_double)

        allow(Stripe::Charge).to receive(:create).with(
          amount:   total_cost.cents,
          currency: "usd",
          customer: customer_double.id
        ).and_return(charge_double)
      end

      it "creates a new order from the cart" do
        expect {
          do_action
        }.to change(Order, :count).by(1)
      end

      describe "post-conditions" do
        before do
          do_action
          user.reload
          order.reload
        end

        it { expect(user.customer_id).to eq customer_double.id }

        it { expect(order.cart_items).to eq cart_items }
        it { expect(order.user).to eq user }
        it { expect(order.amount).to eq total_cost }
        it { expect(order.status).to eq 'waiting_confirmation' }
        it { expect(order.delivery_address).to eq delivery_address }
        it { expect(order.observations).to eq 'Take off the bacon!' }
        it { expect(order.charge_id).to eq charge_double.id }

        it { expect(Cart.exists? cart.id).to be false }
        it { expect(Stripe::Customer).to have_received(:create) }
        it { expect(Stripe::Charge).to have_received(:create) }

        it "redirects to root path" do
          expect(response).to redirect_to root_path
        end

        it "sets a success message" do
          expect(flash[:success]).to eq "Checkout was successful! Waiting confirmation..."
        end
      end

      context "handling failure" do
        context "record errors" do
          before do
            allow_any_instance_of(Cart).to receive(:destroy!).and_raise(ActiveRecord::RecordInvalid, cart)
          end

          it "creates a new order nonetheless" do
            expect {
              do_action
            }.to change(Order, :count).by(1)
          end

          describe "post-conditions" do
            before do
              do_action
            end

            it "undoes the cart destruction" do
              expect(Cart.exists? cart.id).to be true
              expect(cart.reload.shopping_cart_items).to eq cart_items
            end

            it "sets the order to an internal failure status" do
              expect(order.status).to eq 'internal_failure'
            end

            it "shows an error message" do
              expect(flash[:danger]).to eq "Something went wrong. Contact us and we'll solve the problem."
              expect(flash[:success]).to be_nil
            end

            it "doesn't call stripe" do
              expect(Stripe::Customer).not_to have_received(:create)
              expect(Stripe::Charge).not_to have_received(:create)
            end
          end
        end

        context "stripe errors" do
          let(:error_message) { 'some external error' }

          before do
            allow(Stripe::Customer).to receive(:create)
              .and_raise(Stripe::APIError, error_message)
          end

          it "creates a new order nonetheless" do
            expect {
              do_action
            }.to change(Order, :count).by(1)
          end

          describe "post-conditions" do
            before do
              do_action
            end

            it "undoes the cart destruction" do
              expect(Cart.exists? cart.id).to be true
              expect(cart.reload.shopping_cart_items).to eq cart_items
            end

            it "sets the order to an external failure status" do
              expect(order.status).to eq 'external_failure'
            end

            it "shows the error message" do
              expect(flash[:danger]).to eq error_message
              expect(flash[:success]).to be_nil
            end
          end
        end
      end

      context "user already has a credit card (existing Stripe user)" do
        context 'when user pay with existing credit card' do
          before do
            allow(Stripe::Charge).to receive(:create).with(
              amount:   total_cost.cents,
              currency: "usd",
              customer: customer_double.id,
              source: 'some source id'
            ).and_return(charge_double)

            user.update!(customer_id: 'some customer id')

            post :create, order: {
              delivery_time: delivery_time,
              delivery_address: delivery_address,
              source_id: 'some source id'
            }
          end

          it { expect(Stripe::Customer).not_to have_received(:create) }

          it do
            expect(Stripe::Charge).to have_received(:create).with(
              amount:   total_cost.cents,
              currency: 'usd',
              customer: customer_double.id,
              source: 'some source id')
          end
        end

        context 'when user pay with new credit card' do
          let(:sources) { double('Stripe::ListObject') }

          before do
            allow(Stripe::Customer).to(receive(:retrieve)
              .with(customer_double.id)
              .and_return(customer_double))

            allow(customer_double).to receive(:sources) { sources }
            allow(sources).to receive(:create)

            user.update!(customer_id: 'some customer id')
            do_action
          end

          it { expect(Stripe::Customer).not_to have_received(:create) }
          it { expect(Stripe::Customer).to have_received(:retrieve) }
          it { expect(customer_double).to have_received('sources') }
          it { expect(sources).to have_received(:create).with(source: token) }

          it do
            expect(Stripe::Charge).to have_received(:create).with(
              amount:   total_cost.cents,
              currency: 'usd',
              customer: customer_double.id)
          end
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

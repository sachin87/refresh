class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :rememberable,
    :trackable, :validatable, :registerable, :omniauthable,
    omniauth_providers: [:facebook]

  has_many :orders
  has_many :addresses, as: :addressable, dependent: :destroy
  accepts_nested_attributes_for :addresses, allow_destroy: true

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def has_credit_card?
    customer_id.present?
  end

  def credit_cards
    if customer_id.present?
      Stripe::Customer.retrieve(customer_id).sources.all(object: 'card')
    end
  end
end

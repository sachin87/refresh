class Order < ActiveRecord::Base
  monetize :amount_cents
  enum status: %w(pending waiting_confirmation on_the_way delivered internal_failure external_failure canceled)

  belongs_to :user
  has_many :cart_items, as: :owner, dependent: :destroy
  validates :user, :delivery_address, :delivery_time, presence: true

  attr_accessor :source_id

  def charged?
    charge_id.present?
  end

  def refunded?
    refund_id.present?
  end

  rails_admin do
    edit do
      field :status
    end

    list do
      field :user
      field :status
      field :amount do
        pretty_value do
          value.format
        end
      end
      field :charged?
      field :refunded?
      field :delivery_time
      field :delivery_address
      field :created_at
    end
  end
end

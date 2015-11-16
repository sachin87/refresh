class CreditCard
  include ActiveModel::Model
  attr_accessor :number, :exp_year, :exp_month, :cvc
end

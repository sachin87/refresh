require 'rails_helper'

RSpec.describe Category, type: :model do
  let(:category) { build(:category) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "must have at least one gender marked as true" do
      category.male = false
      category.female = false
      expect(category).not_to be_valid
      expect(category.errors).to have_key :male
      expect(category.errors).to have_key :female

      category.female = true
      expect(category).to be_valid

      category.male = true
      expect(category).to be_valid

      category.female = false
      expect(category).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:clothes) }
  end
end

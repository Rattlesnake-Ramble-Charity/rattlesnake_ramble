# frozen_string_literal: true

require "rails_helper"

RSpec.describe Paypal::IpnMessage, type: :model do
  it "is valid with valid attributes" do
    ipn_message = build(:paypal_ipn_message)
    expect(ipn_message).to be_valid
  end

  it "is invalid without a raw_post" do
    ipn_message = build(:paypal_ipn_message, raw_post: nil)
    expect(ipn_message).not_to be_valid
    expect(ipn_message.errors.full_messages).to include("Raw post can't be blank")
  end

  describe "txn_id uniqueness" do
    let!(:existing) { create(:paypal_ipn_message, txn_id: "TXN001") }

    it "is invalid with a duplicate txn_id" do
      duplicate = build(:paypal_ipn_message, txn_id: "TXN001")
      expect(duplicate).not_to be_valid
    end

    it "is enforced at the database level" do
      duplicate = build(:paypal_ipn_message, txn_id: "TXN001")
      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "permits multiple records with nil txn_id" do
      create(:paypal_ipn_message, txn_id: nil)
      another = build(:paypal_ipn_message, txn_id: nil)
      expect(another).to be_valid
      expect { another.save! }.not_to raise_error
    end
  end

  describe "#inspect" do
    it "shows money columns as plain decimals rather than e-notation" do
      message = build(:paypal_ipn_message, mc_gross: 45.00, mc_fee: 1.61)
      expect(message.inspect).to include("mc_gross: 45.0")
      expect(message.inspect).to include("mc_fee: 1.61")
    end
  end

  describe "#verified?" do
    it "is true only when verification_status is verified" do
      expect(build(:paypal_ipn_message, verification_status: "verified")).to be_verified
      expect(build(:paypal_ipn_message, verification_status: "pending")).not_to be_verified
      expect(build(:paypal_ipn_message, verification_status: "invalid")).not_to be_verified
    end
  end
end

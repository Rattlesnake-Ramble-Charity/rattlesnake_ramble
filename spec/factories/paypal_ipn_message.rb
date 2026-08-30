FactoryBot.define do
  factory :paypal_ipn_message, class: "Paypal::IpnMessage" do
    sequence(:txn_id) { |n| "TXN#{n.to_s.rjust(14, '0')}" }
    payment_status { "Completed" }
    txn_type { "web_accept" }
    mc_gross { 45.00 }
    mc_currency { "USD" }
    payer_email { FFaker::Internet.email }
    raw_post { "payment_status=Completed" }
    verification_status { "pending" }
  end
end

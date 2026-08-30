class CreatePaypalIpnMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :paypal_ipn_messages do |t|
      t.string :txn_id
      t.string :payment_status
      t.string :txn_type
      t.decimal :mc_gross, precision: 10, scale: 2
      t.decimal :mc_fee, precision: 10, scale: 2
      t.string :mc_currency
      t.string :invoice
      t.string :item_name
      t.string :payer_email
      t.string :first_name
      t.string :last_name
      t.string :receiver_email
      t.string :business
      t.boolean :test_ipn, null: false, default: false
      t.string :verification_status
      t.string :processing_result
      t.integer :race_entry_id
      t.text :raw_post, null: false
      t.timestamps
    end

    add_index :paypal_ipn_messages, :txn_id, unique: true
    add_index :paypal_ipn_messages, :race_entry_id
  end
end

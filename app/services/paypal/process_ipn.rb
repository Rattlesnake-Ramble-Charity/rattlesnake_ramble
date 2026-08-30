# frozen_string_literal: true

module Paypal
  # Stores an inbound IPN message idempotently (keyed on txn_id), verifies it
  # with PayPal, and creates the RaceEntry for a completed payment. Safe to
  # call repeatedly with the same message: duplicate deliveries are recorded
  # once and produce no additional side effects.
  class ProcessIpn
    INVOICE_PATTERN = /\ARaceEdition(\d+)-Racer(\d+)\z/

    Result = Struct.new(:ipn_message, :race_entry, :entry_created, :retryable_error, :attention_needed, keyword_init: true) do
      def entry_created?
        !!entry_created
      end

      def retryable_error?
        !!retryable_error
      end

      def needs_admin_attention?
        !!attention_needed
      end
    end

    def self.perform(raw_post:)
      new(raw_post: raw_post).perform
    end

    def initialize(raw_post:)
      @raw_post = raw_post
      @fields = normalize_encoding(Rack::Utils.parse_query(raw_post))
      @entry_created = false
    end

    def perform
      find_or_create_message

      # A message already verified (or found invalid) is a duplicate delivery;
      # only fresh messages and prior transient verification errors proceed
      return Result.new(ipn_message: message) unless message.previously_new_record? || message.verification_status == "error"

      message.update!(verification_status: Paypal::VerifyIpn.perform(raw_post))
      return Result.new(ipn_message: message, retryable_error: true) if message.verification_status == "error"
      return Result.new(ipn_message: message) unless message.verified?

      process_payment

      Result.new(
        ipn_message: message,
        race_entry: race_entry,
        entry_created: entry_created,
        attention_needed: message.needs_attention?
      )
    end

    private

    attr_reader :raw_post, :fields
    attr_accessor :message, :race_entry, :entry_created

    def find_or_create_message
      self.message =
        if txn_id
          Paypal::IpnMessage.create_with(message_attributes).find_or_create_by!(txn_id: txn_id)
        else
          Paypal::IpnMessage.create!(message_attributes)
        end
    rescue ActiveRecord::RecordNotUnique
      # Concurrent delivery of the same message; the other request won the insert
      self.message = Paypal::IpnMessage.find_by!(txn_id: txn_id)
    end

    def process_payment
      return record_result("ignored_payment_status") unless fields["payment_status"] == "Completed"
      return record_result("receiver_mismatch") unless receiver_ok?
      return record_result("invoice_unrecognized") unless race_edition && racer
      return record_result("amount_mismatch") unless amount_ok?

      create_or_update_entry
    end

    def create_or_update_entry
      self.race_entry = RaceEntry.find_or_initialize_by(race_edition: race_edition, racer: racer)

      if race_entry.new_record?
        race_entry.paid = true
        race_entry.save!
        self.entry_created = true
        record_result(merchandise_implied? ? "created_merch_size_unknown" : "race_entry_created")
      else
        race_entry.update!(paid: true) unless race_entry.paid?
        record_result("race_entry_already_exists")
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      # The buyer's browser return created the entry between our find and save
      self.race_entry = RaceEntry.find_by!(race_edition: race_edition, racer: racer)
      race_entry.update!(paid: true) unless race_entry.paid?
      record_result("race_entry_already_exists")
    end

    def record_result(result)
      message.update!(processing_result: result, race_entry: race_entry)
    end

    def receiver_ok?
      expected = RambleConfig.paypal_business_email
      [fields["receiver_email"], fields["business"]].any? { |email| email.to_s.casecmp?(expected) }
    end

    def amount_ok?
      return false unless fields["mc_currency"] == "USD"
      return false if mc_gross.nil?

      mc_gross == entry_fee || merchandise_implied?
    end

    def merchandise_implied?
      race_edition.selling_merchandise &&
        race_edition.merchandise_price.present? &&
        mc_gross == entry_fee + race_edition.merchandise_price
    end

    def mc_gross
      @mc_gross ||= parse_decimal(fields["mc_gross"])
    end

    def entry_fee
      race_edition.entry_fee
    end

    def race_edition
      return @race_edition if defined?(@race_edition)

      @race_edition = invoice_match && RaceEdition.find_by(id: invoice_match[1])
    end

    def racer
      return @racer if defined?(@racer)

      @racer = invoice_match && Racer.find_by(id: invoice_match[2])
    end

    def invoice_match
      @invoice_match ||= INVOICE_PATTERN.match(fields["invoice"].to_s)
    end

    def txn_id
      fields["txn_id"].presence
    end

    def parse_decimal(value)
      BigDecimal(value.to_s)
    rescue ArgumentError
      nil
    end

    # PayPal encodes IPN values in windows-1252 unless the account is
    # configured for UTF-8; the message declares its encoding in the charset
    # field. Values must be valid UTF-8 before they reach Postgres.
    def normalize_encoding(fields)
      encoding = declared_encoding(fields)
      fields.transform_values { |value| normalize_value(value, encoding) }
    end

    def declared_encoding(fields)
      name = fields["charset"].to_s
      return nil if name.empty?

      encoding = Encoding.find(name)
      encoding == Encoding::UTF_8 ? nil : encoding
    rescue ArgumentError
      nil
    end

    def normalize_value(value, encoding)
      return value unless value.is_a?(String)

      utf8_value = encoding ? value.dup.force_encoding(encoding).encode(Encoding::UTF_8) : value
      utf8_value.valid_encoding? ? utf8_value : utf8_value.scrub
    rescue EncodingError
      value.scrub
    end

    def storable_raw_post
      utf8_value = raw_post.dup.force_encoding(Encoding::UTF_8)
      utf8_value.valid_encoding? ? utf8_value : utf8_value.scrub
    end

    def message_attributes
      {
        txn_id: txn_id,
        payment_status: fields["payment_status"],
        txn_type: fields["txn_type"],
        mc_gross: parse_decimal(fields["mc_gross"]),
        mc_fee: parse_decimal(fields["mc_fee"]),
        mc_currency: fields["mc_currency"],
        invoice: fields["invoice"],
        item_name: fields["item_name"],
        payer_email: fields["payer_email"],
        first_name: fields["first_name"],
        last_name: fields["last_name"],
        receiver_email: fields["receiver_email"],
        business: fields["business"],
        test_ipn: fields["test_ipn"] == "1",
        raw_post: storable_raw_post,
        verification_status: "pending",
      }
    end
  end
end

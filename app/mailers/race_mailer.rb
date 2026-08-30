class RaceMailer < ApplicationMailer
  def payment_acknowledgment(race_entry)
    @race_entry = race_entry
    @racer = race_entry.racer
    @race_edition = race_entry.race_edition
    @course_name = course_name
    @race_date = formatted_date

    mail(
      to: @racer.email,
      subject: "Yayy! You’re entered in #{@course_name} on #{@race_date}"
    )
  end

  def reminder(race_entry, timing_label:)
    @race_entry = race_entry
    @racer = race_entry.racer
    @race_edition = race_entry.race_edition
    @timing_label = timing_label
    @course_name = course_name
    @race_date = formatted_date

    mail(
      to: @racer.email,
      subject: "Reminder: #{@course_name} on #{@race_date} is #{timing_label}"
    )
  end

  def ipn_attention_needed(ipn_message)
    @ipn_message = ipn_message

    mail(
      to: RambleConfig.paypal_business_email,
      subject: "PayPal IPN needs attention: #{ipn_message.processing_result&.humanize&.downcase}"
    )
  end

  private

  def course_name
    @race_edition.race&.short_name.presence ||
      @race_edition.race&.name.presence ||
      @race_edition.name
  end

  def formatted_date
    return "the race date" unless @race_edition.date

    date = @race_edition.date
    "#{date.strftime('%B')} #{date.day.ordinalize}"
  end
end

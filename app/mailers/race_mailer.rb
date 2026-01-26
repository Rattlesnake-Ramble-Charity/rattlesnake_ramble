class RaceMailer < ApplicationMailer
  def payment_acknowledgment(race_entry)
    @race_entry = race_entry
    @racer = race_entry.racer
    @race_edition = race_entry.race_edition

    mail(
      to: @racer.email,
      subject: "You’re entered in #{@race_edition.name}"
    )
  end

  def reminder(race_entry, timing_label:)
    @race_entry = race_entry
    @racer = race_entry.racer
    @race_edition = race_entry.race_edition
    @timing_label = timing_label

    mail(
      to: @racer.email,
      subject: "#{@race_edition.name} is #{timing_label}"
    )
  end
end

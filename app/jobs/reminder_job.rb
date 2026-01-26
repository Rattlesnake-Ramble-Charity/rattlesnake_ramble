class ReminderJob < ApplicationJob
  queue_as :default

  def perform(race_entry_id, timing_label)
    race_entry = RaceEntry.includes(:racer, :race_edition).find_by(id: race_entry_id)
    return unless race_entry&.racer&.email.present?

    RaceMailer.reminder(race_entry, timing_label: timing_label).deliver_now
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReminderJob do
  let(:race_edition) { FactoryBot.create(:race_edition, :full_course, date: "2026-09-12") }
  let(:racer) { FactoryBot.create(:racer, first_name: "Jane", email: "jane@example.com") }
  let(:race_entry) { FactoryBot.create(:race_entry, race_edition: race_edition, racer: racer) }

  before { ActionMailer::Base.deliveries.clear }

  describe "#perform" do
    it "sends the reminder to the racer" do
      expect do
        described_class.perform_now(race_entry.id, "tomorrow")
      end.to change(ActionMailer::Base.deliveries, :count).by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq(["jane@example.com"])
      expect(mail.subject).to eq("Reminder: Full Course on September 12th is tomorrow")
    end

    it "does nothing when the race entry no longer exists" do
      expect do
        described_class.perform_now(-1, "tomorrow")
      end.not_to change(ActionMailer::Base.deliveries, :count)
    end

    it "does nothing when the racer has no email" do
      racer.update_column(:email, "")

      expect do
        described_class.perform_now(race_entry.id, "tomorrow")
      end.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe "enqueueing" do
    it "enqueues on the default queue with the entry id and timing label" do
      expect do
        described_class.perform_later(race_entry.id, "one week away")
      end.to have_enqueued_job(described_class).with(race_entry.id, "one week away").on_queue("default")
    end
  end
end

class RaceEntriesController < ApplicationController
  before_action :authenticate_user!, except: [:successful_entry, :cancelled_payment]

  def edit
    @race_entry = RaceEntryPresenter.new(RaceEntry.find(params[:id]))
  end

  def update
    @race_entry = RaceEntry.find(params[:id])
    if @race_entry.update(obj_params)
      flash[:success] = "Your race entry was updated successfully"
      redirect_to race_entries_race_edition_path(@race_entry.race_edition)
    end
  end

  def destroy
    @race_entry = RaceEntry.find(params[:id])
    if @race_entry.destroy
      flash[:success] = "Your race entry was deleted"
      redirect_to race_entries_race_edition_path(@race_entry.race_edition)
    end
  end

  def successful_entry
    race_entry = RaceEntry.find(params[:id])
    race_entry.paid = true
    if race_entry.save
      flash[:success] = "Get ready to Ramble, because you are entered!"
      RaceMailer.payment_acknowledgment(race_entry).deliver_later

      race_date = race_entry.race_edition.date
      if race_date.present?
        race_time = race_date.to_time.in_time_zone(race_entry.race_edition.home_time_zone)
        ReminderJob.set(wait_until: race_time - 7.days).perform_later(race_entry.id, "one week away")
        ReminderJob.set(wait_until: race_time - 1.day).perform_later(race_entry.id, "tomorrow")
      end

      redirect_to race_edition_path(race_entry.race_edition)
    end
  end

  def cancelled_payment
    race_entry = RaceEntry.find(params[:id])
    flash[:success] = "Until you pay, you are not officially in the Rattlesnake Ramble. Please pay via PayPal promptly or contact the race director (bwright@rattlesnakeramble.org)."
    redirect_to race_edition_path(race_entry.race_edition)
  end

  private

  def obj_params
    params.require(:race_entry).permit(:racer, :race_edition, :paid, :time, :bib_number, :scheduled_start_time_local, :merchandise_size)
  end
end

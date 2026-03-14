# frozen_string_literal: true

class RaceEditionsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :enter, :create_entry, :payment_success, :payment_cancelled]
  before_action :set_race_edition, except: [:index, :new, :create]

  def index
    respond_to do |format|
      format.json { authenticate_with_params! }
    end
  end

  def show
    @race_edition = RaceEdition.includes(:race, race_entries: :racer).find_by(id: @race_edition.id)

    respond_to do |format|
      format.html { @presenter = RaceEditionPresenter.new(@race_edition, params) }
      format.json { authenticate_with_params! }
    end
  end

  def new
    @race_edition = RaceEdition.new(obj_params)
  end

  def create
    @race_edition = RaceEdition.new(obj_params)

    if @race_edition.save
      flash[:success] = "Your race edition was created successfully!"
      redirect_to race_edition_path(@race_edition)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @race_edition.update(obj_params)
      flash[:success] = "Your race edition was updated successfully"
      redirect_to race_edition_path(@race_edition)
    else
      render :edit
    end
  end

  def destroy
    if @race_edition.destroy
      flash[:success] = "Your race edition was deleted"
      redirect_to races_path
    end
  end

  def enter
    @racer = Racer.new
    @race_entry = RaceEntry.new
  end

  def race_entries
    @race_edition = RaceEditionPresenter.new(@race_edition, params)
  end

  def create_entry
    @racer = Racer.new(obj_params[:racers_attributes]['0'])

    # capture race-entry attributes the form collected (e.g., merchandise_size)
    provided_race_entry_attributes = obj_params[:race_entries_attributes]['0'] || {}
    merch_size = provided_race_entry_attributes['merchandise_size'].presence

    if @racer.save
      # hand the user to PayPal; on return we'll create the RaceEntry as paid: true
      redirect_to paypal_checkout_url_for(@racer, merch_size), allow_other_host: true
    else
      # re-render form with errors; ensure @race_entry exists for fields_for
      default_race_entry_attributes = { race_edition: @race_edition, racer: @racer }
      @race_entry = RaceEntry.new(default_race_entry_attributes.merge(provided_race_entry_attributes))
      @race_entry.validate
      @racer.errors.merge!(@race_entry.errors)
      render 'enter'
    end
  end

  def paypal_url(race_entry)
    item_number = "RaceEdition#{@race_edition.id}-Racer#{race_entry.racer.id}"
    total_value = @race_edition.entry_fee
    if race_entry.merchandise_size?
      total_value += @race_edition.merchandise_price
    end

    values = {
      business: "bwright@rattlesnakeramble.org",
      cmd: "_xclick",
      upload: 1,
      return: "#{Rails.application.secrets.app_host}#{successful_entry_race_entry_path(race_entry)}",
      cancel_return: "#{Rails.application.secrets.app_host}#{cancelled_payment_race_entry_path(race_entry)}",
      invoice: "RaceEntry#{race_entry.id}",
      amount: total_value,
      item_name: @race_edition.name,
      item_number: item_number,
      quantity: '1',
      shipping: 0,
      handling: 0,
      no_shipping: 1,
      no_note: 1,
    }

    paypal_url = "#{Rails.application.secrets.paypal_host}/cgi-bin/webscr?" + values.to_query
    Rails.logger.debug "From RaceEditionsController>>paypal_url: #{paypal_url}"
    paypal_url

  end

  helper_method :paypal_url

  def paypal_checkout_url_for(racer, merch_size)
    total_value = @race_edition.entry_fee
    total_value += @race_edition.merchandise_price if merch_size.present?

    values = {
      business: "bwright@rattlesnakeramble.org",
      cmd: "_xclick",
      upload: 1,

      # Return to the RaceEdition, not a RaceEntry (we don’t have an entry yet)
      return: "#{Rails.application.secrets.app_host}#{payment_success_race_edition_path(@race_edition)}?racer_id=#{racer.id}&merchandise_size=#{merch_size}",
      cancel_return: "#{Rails.application.secrets.app_host}#{payment_cancelled_race_edition_path(@race_edition)}",

      # Use an invoice that identifies racer + edition (no RaceEntry id yet)
      invoice: "RaceEdition#{@race_edition.id}-Racer#{racer.id}",

      amount: total_value,
      item_name: @race_edition.name,
      quantity: 1,
      currency_code: "USD",
      shipping: 0,
      handling: 0,
      no_shipping: 1,
      no_note: 1,
    }

    # "#{Rails.application.secrets.paypal_host}/cgi-bin/webscr?" + values.to_query
    paypal_url = "#{Rails.application.secrets.paypal_host}/cgi-bin/webscr?" + values.to_query
    Rails.logger.debug "From RaceEditionsController>>paypal_checkout_url_for: #{paypal_url}"
    paypal_url
  end

  helper_method :paypal_checkout_url_for

  def racer_emails
    all_entries = @race_edition.race_entries.eager_load(:racer)
    paid_filter = params[:filter] && (params[:filter][:paid] == 'true')
    filtered_entries = paid_filter.nil? ? all_entries : all_entries.where(paid: paid_filter)
    @racers = filtered_entries.map(&:racer)
  end

  def racer_info_csv
  end

  def payment_success
    # set_race_edition already ran; we also need the racer
    racer = Racer.find(params[:racer_id])

    attrs = {}
    attrs[:merchandise_size] = params[:merchandise_size] if params[:merchandise_size].present?

    entry = RaceEntry.create!(
      race_edition: @race_edition,
      racer: racer,
      paid: true,
      **attrs
    )

    flash[:success] = "Get ready to Ramble, because you are entered!"
    send_payment_ack_and_schedule_reminders(entry)
    redirect_to race_edition_path(@race_edition)
  end

  def payment_cancelled
    flash[:success] = "Until you pay, you are not officially in the Rattlesnake Ramble. Please pay via PayPal promptly or contact the race director (bwright@rattlesnakeramble.org)."
    redirect_to race_edition_path(@race_edition)
  end

  def checkin_sheet
    @race_edition = RaceEdition.friendly.find(params[:id])
    @entries = @race_edition.race_entries
                             .includes(:racer)
                             .joins(:racer)
                             .order('LOWER(racers.last_name), LOWER(racers.first_name)')
    render :checkin_sheet
  end


  private

  def obj_params
    params.require(:race_edition)
      .permit(:race_id, :date, :entry_fee, :default_start_time_male_local, :default_start_time_female_local, :next_male_bib_number, :next_female_bib_number, :next_kids_bib_number, :accepting_entries, :selling_merchandise, :merchandise_description, :merchandise_image_file_name, :merchandise_price,
              racers_attributes: [:id, :first_name, :last_name, :email, :gender, :birth_date, :city, :state],
              race_entries_attributes: [:elapsed_predicted_time, :merchandise_size])
  end

  def set_race_edition
    @race_edition = RaceEdition.friendly.find(params[:id])
    return if request.format == "application/json"

    friendly_redirect(@race_edition, params[:id])
  end

  def send_payment_ack_and_schedule_reminders(race_entry)
    RaceMailer.payment_acknowledgment(race_entry).deliver_later

    race_date = race_entry.race_edition.date
    return unless race_date.present?
    race_time = race_date.to_time.in_time_zone(race_entry.race_edition.home_time_zone)

    # enqueue reminders relative to race date
    ReminderJob.set(wait_until: race_time - 7.days).perform_later(race_entry.id, "one week away")
    ReminderJob.set(wait_until: race_time - 1.day).perform_later(race_entry.id, "tomorrow")
  end
end

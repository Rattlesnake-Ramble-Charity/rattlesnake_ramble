class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def authenticate_with_params!
    user = User.find_by(email: params.dig(:user, :email))

    unless user.present? && user.valid_password?(params.dig(:user, :password))
      render json: { errors: ["Invalid email or password"] }, status: :unauthorized
    end
  end

  # If an old friendly id or a numeric id was used to find the record, then
  # the request id will not match the current friendly id, and we should do
  # a 301 redirect that uses the current friendly id.
  def friendly_redirect(resource, id_param)
    if request.request_method_symbol == :get && resource.friendly_id != id_param
      redirect_to request.params.merge(id: resource.friendly_id), status: :moved_permanently
    end
  end

  private

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

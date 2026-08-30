# frozen_string_literal: true

class PaypalIpnMessagesController < ApplicationController
  before_action :authenticate_user!

  def index
    @messages = Paypal::IpnMessage.includes(race_entry: [:racer, :race_edition]).order(created_at: :desc)
    @messages = @messages.needs_attention if params[:filter] == "attention"
    @messages = @messages.limit(200)
  end

  def show
    @message = Paypal::IpnMessage.find(params[:id])
  end
end

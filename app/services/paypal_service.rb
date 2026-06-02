# frozen_string_literal: true

class PaypalService
  API_BASE_SANDBOX = 'https://api-m.sandbox.paypal.com'
  API_BASE_LIVE    = 'https://api-m.paypal.com'

  def initialize
    @client_id     = Rails.application.secrets.paypal_client_id
    @client_secret = Rails.application.secrets.paypal_client_secret
    @base_url      = Rails.env.production? ? API_BASE_LIVE : API_BASE_SANDBOX
  end

  def create_order(amount:, item_name:, invoice_id:)
    body = {
      intent: 'CAPTURE',
      purchase_units: [{
        reference_id: invoice_id,
        description:  item_name,
        amount: {
          currency_code: 'USD',
          value:         format('%.2f', amount)
        }
      }]
    }

    response = RestClient.post(
      "#{@base_url}/v2/checkout/orders",
      body.to_json,
      authorization_headers
    )
    JSON.parse(response.body)
  end

  def capture_order(order_id)
    response = RestClient.post(
      "#{@base_url}/v2/checkout/orders/#{order_id}/capture",
      '{}',
      authorization_headers
    )
    JSON.parse(response.body)
  end

  private

  def access_token
    response = RestClient.post(
      "#{@base_url}/v1/oauth2/token",
      'grant_type=client_credentials',
      'Authorization'  => "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}",
      'Content-Type'   => 'application/x-www-form-urlencoded'
    )
    JSON.parse(response.body)['access_token']
  end

  def authorization_headers
    {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type'  => 'application/json'
    }
  end
end

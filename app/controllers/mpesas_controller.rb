class MpesasController < ApplicationController
  require "rest-client"
  rescue_from SocketError, with: :OfflineMode

  def stkpush
    phoneNumber = params[:phoneNumber]
    amount = params[:amount]

    url = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
    timestamp = "#{Time.now.strftime "%Y%m%d%H%M%S"}"
    business_short_code = ENV["MPESA_SHORTCODE"]
    password =
      Base64.strict_encode64(
        "#{business_short_code}#{ENV["MPESA_PASSKEY"]}#{timestamp}"
      )

    payload = {
      BusinessShortCode: business_short_code,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerPayBillOnline",
      Amount: amount,
      PartyA: phoneNumber,
      PartyB: business_short_code,
      PhoneNumber: phoneNumber,
      CallBackURL: "#{ENV["CALLBACK_URL"]}/callback_url",
      AccountReference: "Trial ROR Mpesa",
      TransactionDesc: "ROR trial"
    }.to_json

    headers = {
      content_type: "application/json",
      Authorization: "Bearer #{get_access_token}"
    }
    response =
      RestClient::Request
        .new({ method: :post, url: url, payload: payload, headers: headers })
        .execute do |response, request|
          case response.code
          when 500
            [:error, JSON.parse(response.to_str)]
          when 400
            [:error, JSON.parse(response.to_str)]
          when 200
            [:success, JSON.parse(response.to_str)]
          else
            fail "Invalid response #{response.to_str} received."
          end
        end

    render json: response
  end

  def polling_payment
    # Check if payment has been paid
    checkoutId = params[:checkoutRequestID]

    timestamp = "#{Time.now.strftime "%Y%m%d%H%M%S"}"
    business_short_code = ENV["MPESA_SHORTCODE"]
    password =
      Base64.strict_encode64(
        "#{business_short_code}#{ENV["MPESA_PASSKEY"]}#{timestamp}"
      )

    url = ENV["QUERY_URL"]

    headers = {
      content_type: "application/json",
      Authorization: "Bearer #{get_access_token}"
    }

    payload = {
      "BusinessShortCode" => business_short_code,
      "Password" => password,
      "Timestamp" => timestamp,
      "CheckoutRequestID" => checkoutId
    }.to_json

    response =
      RestClient::Request
        .new({ method: :post, url: url, payload: payload, headers: headers })
        .execute do |response, request|
          puts response
          case response.code
          when 500
            [:error, JSON.parse(response.to_str)]
          when 400
            [:error, JSON.parse(response.to_str)]
          when 200
            [:success, JSON.parse(response.to_str)]
          else
            fail "Invalid response #{response.to_str} received."
          end
        end

    render json: response
  end

  private

  def generate_access_token_request
    @url =
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"

    @consumer_key = ENV["MPESA_CONSUMER_KEY"]
    @consumer_secret = ENV["MPESA_CONSUMER_SECRET"]
    @userpass = Base64.strict_encode64("#{@consumer_key}:#{@consumer_secret}")
    @headers = { Authorization: "Bearer #{@userpass}" }

    res =
      RestClient::Request.execute(
        url: @url,
        method: :get,
        headers: {
          Authorization: "Basic #{@userpass}"
        }
      )
    res
  end

  def get_access_token
    res = generate_access_token_request
    if res.code != 200
      r = generate_access_token_request
      raise MpesaError("Unable to generate access token") if res.code != 200
    end
    body = JSON.parse(res, { symbolize_names: true })
    token = body[:access_token]
    AccessToken.destroy_all()
    AccessToken.create!(token: token)
    token
  end

  def OfflineMode
    render json: { errors: ["You are Offline Do Connect to the Internet"] }
  end
end

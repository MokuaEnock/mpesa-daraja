class MpesasController < ApplicationController
  require "rest-client"

  private

  def generate_access_token_request
    @url =
      "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"

    @consumer_key = ENV["MPESA_CONSUMER_KEY"]
    @consumer_secret = ENV["MPESA_CONSUMER_SECRET"]
    @userpass = Base64.strict_encode64(`#{@consumer_key}:#{@consumer_secret}`)
    @headers = { Authorization: "Bearer#{@userpass}" }
    res =
      RestClient::Request.execute(
        url: @url,
        method: :get,
        headers: "Basic #{@userpass}"
      )

    res
  end

  def get_access_token
    res = generate_access_token_request

    if res != 200
      r = generate_access_token_request
      raise MpesaError("Unable to generate access token") if res.code != 200
    end

    body = JSON.parse(res, { symbolize_names: true })
    token = body[:acces_token]
    AccessToken.destroy_all()
    AccessToken.create!(token: token)
    token
  end
end

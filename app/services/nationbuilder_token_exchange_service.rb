require "net/http"
require "uri"
require "json"

class NationbuilderTokenExchangeService
  class TokenExchangeError < StandardError; end

  def initialize(client_id:, client_secret:, redirect_uri:)
    @client_id = client_id
    @client_secret = client_secret
    @redirect_uri = redirect_uri
    @nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
  end

  def exchange_code_for_token(code)
    uri = URI.parse("https://#{@nation_slug}.nationbuilder.com/oauth/token")
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: @redirect_uri,
      code: code,
      grant_type: "authorization_code"
    )
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
    unless res.is_a?(Net::HTTPSuccess)
      raise TokenExchangeError, "Token exchange failed: #{res.code} - #{res.body}"
    end
    JSON.parse(res.body, symbolize_names: true)
  end
end

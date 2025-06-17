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
    
    Rails.logger.info "NationBuilder OAuth: Exchanging code for token"
    Rails.logger.info "NationBuilder OAuth: Nation slug: #{@nation_slug}"
    Rails.logger.info "NationBuilder OAuth: Redirect URI: #{@redirect_uri}"
    
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
      Rails.logger.error "NationBuilder OAuth: Token exchange failed"
      Rails.logger.error "NationBuilder OAuth: Response code: #{res.code}"
      Rails.logger.error "NationBuilder OAuth: Response body: #{res.body}"
      
      error_data = JSON.parse(res.body) rescue {}
      error_message = error_data["error_description"] || error_data["error"] || "Unknown error"
      
      raise TokenExchangeError, error_message
    end
    
    JSON.parse(res.body, symbolize_names: true)
  end
end

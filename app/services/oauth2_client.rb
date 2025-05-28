class Oauth2Client
  def initialize(client_id:, client_secret:, redirect_uri:, scopes:)
    @client_id = client_id
    @client_secret = client_secret
    @redirect_uri = redirect_uri
    @scopes = scopes
    @nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
    raise "NATIONBUILDER_NATION_SLUG environment variable is not set" if @nation_slug.nil? || @nation_slug.strip.empty?
  end

  def authorization_url(state: nil)
    auth_url = "https://#{@nation_slug}.nationbuilder.com/oauth/authorize"
    params = {
      client_id: @client_id,
      redirect_uri: @redirect_uri,
      response_type: "code",
      scope: @scopes.join(" ")
    }
    params[:state] = state if state
    query = URI.encode_www_form(params)
    "#{auth_url}?#{query}"
  end
end

require "uri"

# Helper method for safely generating database URLs with suffixes
def database_url_with_suffix(suffix)
  database_url = ENV["DATABASE_URL"]
  return nil if database_url.nil? || database_url.strip.empty?

  begin
    uri = URI.parse(database_url)

    # Ensure we have a valid scheme (postgres, postgresql, etc.)
    return nil unless uri.scheme

    # Extract database name from path, handling cases like "/mydb" or "/path/to/mydb"
    db_name = uri.path.split("/").last

    if db_name && !db_name.empty?
      # Use existing database name with suffix
      uri.path = "/#{db_name}_#{suffix}"
    else
      # Fallback to default database name with suffix
      uri.path = "/jupiter_production_#{suffix}"
    end

    uri.to_s
  rescue URI::InvalidURIError => e
    warn "Invalid DATABASE_URL format: #{e.message}" if $VERBOSE
    nil
  end
end

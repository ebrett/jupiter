# Configure ActiveRecord session store with custom table name
Rails.application.config.session_store :active_record_store, 
  key: '_jupiter_session',
  table_name: 'rails_sessions',
  same_site: :lax
# Configure ActiveRecord session store to use custom table
ActiveRecord::SessionStore::Session.table_name = "rails_sessions"

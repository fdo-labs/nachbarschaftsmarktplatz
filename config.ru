# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Fairmondo::Application

# workaround to access sidekiq web without using rack for session management
# todo: change as soon a fix for https://github.com/rack/rack/issues/1531
# code is taken from https://github.com/mperham/sidekiq/wiki/Monitoring#standalone-with-basic-auth
require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end

require 'sidekiq/web'
map '/sidekiq_' do
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    # Protect against timing attacks:
    # - See https://codahale.com/a-lesson-in-timing-attacks/
    # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
    # - Use & (do not use &&) so that it doesn't short circuit.
    # - Use digests to stop length information leaking
    Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest( Rails.application.secrets.sidekiq_username )) &
      Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest( Rails.application.secrets.sidekiq_password ))
  end

  run Sidekiq::Web
end
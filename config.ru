require 'rubygems'
require 'geminabox'

Geminabox.data = '/var/geminabox-data' # ... or wherever
Geminabox.rubygems_proxy = ENV['RUBYGEMS_PROXY'] == 'true'
Geminabox.allow_remote_failure = ENV['ALLOW_REMOTE_FAILURE'] == 'true'
Geminabox.rubygems_proxy_merge_strategy = ENV['RUBYGEMS_PROXY_MERGE_STRATEGY']&.to_sym || :combine_local_and_remote_gem_versions

# Use Rack::Protection to prevent XSS and CSRF vulnerability if your geminabox server is open public.
# Rack::Protection requires a session middleware, choose your favorite one such as Rack::Session::Memcache.
# This example uses Rack::Session::Pool for simplicity, but please note that:
# 1) Rack::Session::Pool is not available for multiprocess servers such as unicorn
# 2) Rack::Session::Pool causes memory leak (it does not expire stored `@pool` hash)
use Rack::Session::Pool, expire_after: 1000 # sec
use Rack::Protection

# Basic Authentication
USERNAME = ENV['BASIC_USER']
PASSWORD = ENV['BASIC_PASS']

unless USERNAME.to_s.empty? && PASSWORD.to_s.empty?
  Geminabox::Server.helpers do
    def protected!
      return if authorized?

      response['WWW-Authenticate'] = %(Basic realm="Geminabox")
      halt 401, "No pushing or deleting without auth.\n"
    end

    def authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [USERNAME, PASSWORD]
    end
  end

  Geminabox::Server.before '/upload' do
    protected!
  end

  Geminabox::Server.before do
    protected! if request.delete?
  end

  Geminabox::Server.before '/api/v1/gems' do
    halt 401, "Access Denied. Api_key invalid or missing.\n" unless env['HTTP_AUTHORIZATION'] == 'API_KEY'
  end
end

run Geminabox::Server

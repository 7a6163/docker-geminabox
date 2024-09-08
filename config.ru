require 'rubygems'
require 'geminabox'

Geminabox.data = '/var/geminabox-data'
Geminabox.rubygems_proxy = ENV['RUBYGEMS_PROXY'] == 'true'
Geminabox.allow_remote_failure = ENV['ALLOW_REMOTE_FAILURE'] == 'true'
Geminabox.rubygems_proxy_merge_strategy = ENV['RUBYGEMS_PROXY_MERGE_STRATEGY']&.to_sym || :combine_local_and_remote_gem_versions

use Rack::Config do |env|
  env['HTTPS'] = 'on' if env['HTTP_X_FORWARDED_PROTO'] == 'https'
end

use Rack::Session::Pool, expire_after: 1000 # sec
use Rack::Protection, except: [:http_origin]

# Basic Authentication
USERNAME = ENV['BASIC_USER']
PASSWORD = ENV['BASIC_PASS']

unless USERNAME.to_s.empty? && PASSWORD.to_s.empty?
  use Rack::Auth::Basic, 'Geminabox' do |username, password|
    [username, password] == [USERNAME, PASSWORD]
  end

  Geminabox::Server.helpers do
    def protected!
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      return if @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [USERNAME, PASSWORD]

      response['WWW-Authenticate'] = %(Basic realm="Geminabox")
      halt 401, "Authentication required.\n"
    end
  end

  Geminabox::Server.before do
    protected!
  end

  Geminabox::Server.before '/api/v1/gems' do
    halt 401, "Access Denied. Api_key invalid or missing.\n" unless env['HTTP_AUTHORIZATION'] == ENV['API_KEY']
  end
end

run Geminabox::Server

# frozen_string_literal: true

require 'pry'
require 'time'

require_relative 'server'
require_relative 'database'
require_relative 'client'

@db_name = 'access'

unless Database.key?('credentials', 'client_id')
  puts 'Insert Client ID:'
  client_id = gets.chomp
  puts 'Insert Client Secret:'
  client_secret = gets.chomp

  Database.store('credentials', { 'client_id' => client_id, 'client_secret' => client_secret })
end

@client_id     = Database.get_value('credentials', 'client_id')
@client_secret = Database.get_value('credentials', 'client_secret')

@redirect_uri = CGI.escape('http://localhost:4567/callback')
@scopes       = 'playlist-modify-private'

@base_url  = 'https://accounts.spotify.com'
@auth_url  = "#{@base_url}/authorize"
@token_url = "#{@base_url}/api/token"

def auth_url
  "#{@auth_url}?client_id=#{@client_id}&response_type=code&redirect_uri=#{@redirect_uri}&scope=#{@scopes}"
end

def authorize
  Database.delete(@db_name, 'code') if Database.key?(@db_name, 'code')

  server_thread = Thread.new { run Server.run! }

  open_in_browser(auth_url)

  sleep 0.1 until Database.key?(@db_name, 'code')
  server_thread.exit

  response = exchange_code(Database.get_value(@db_name, 'code'))
  Database.store(@db_name, response.merge!('expires_at' => expires_at(response['expires_in'])))
end

def open_in_browser(url)
  case RbConfig::CONFIG['host_os']
  when /mswin|mingw|cygwin/ then system "start \"\" \"#{url}\""
  when /linux|bsd/          then system "xdg-open #{url}"
  end
end

def expires_at(expires_in)
  (Time.now + expires_in).to_s
end

def token_expired?(expires_at)
  return true unless expires_at

  Time.now > (Time.parse(expires_at) - 60)
end

def exchange_code(code)
  Client.post(
    @token_url,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
    },
    payload: { grant_type: 'authorization_code', code: code, redirect_uri: @redirect_uri },
    preparsed: true
  )
end

def refresh_token
  json = Client.post(
    @token_url,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
    },
    payload: { grant_type: 'refresh_token', refresh_token: Database.get_value(@db_name, 'refresh_token') },
    preparsed: true
  )

  Database.store(@db_name, { 'access_token' => json['access_token'], 'expires_at' => expires_at(json['expires_in']) })
end

authorize unless Database.key?(@db_name, 'access_token')

refresh_token if token_expired?(Database.get_value(@db_name, 'expires_at'))

puts Database.get_value(@db_name, 'expires_at')
puts Database.get_value(@db_name, 'access_token')

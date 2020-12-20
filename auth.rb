require "uri"
require 'net/http'
require 'pry'
require 'base64'
require 'cgi'
require 'dbm'
require 'json'
require 'time'

require_relative 'server'
require_relative 'database'

@db_name = "access"

@client_id     = "bd1b5b5c8df84d06aab47b28969060b4"
@client_secret = "e894025a81c54a7198ec9e534fdc42cf"

@redirect_uri = CGI.escape("http://localhost:4567/callback")
@scopes       = "playlist-modify-private"

@base_url  = "https://accounts.spotify.com"
@auth_url  = "#{@base_url}/authorize"
@token_url = "#{@base_url}/api/token"

def generate_auth_url
  "#{@auth_url}?client_id=#{@client_id}&response_type=code&redirect_uri=#{@redirect_uri}&scope=#{@scopes}"
end

def authorize
  puts "Start Authorization"
  Database.delete(@db_name, "code") if Database.has_key?(@db_name, "code")

  server_thread = Thread.new { run Server.run! }

  if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    system "start \"\" \"#{generate_auth_url}\""
  elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
    system "xdg-open #{generate_auth_url}"
  end

  sleep 0.1 until Database.has_key?(@db_name, "code")

  server_thread.exit

  code = Database.get_value(@db_name, "code")

  response = exchange_code(code)
  json = JSON.parse(response.body)

  Database.store(@db_name, json.merge!("expires_at" => expires_at(json["expires_in"])))
end

def expires_at(expires_in)
  (Time.now + expires_in).to_s
end

def token_expired?(expires_at)
  return true unless expires_at
  Time.now > (Time.parse(expires_at) - 60)
end

def exchange_code(code)
  url           = URI(@token_url)
  https         = Net::HTTP.new(url.host, url.port);
  https.use_ssl = true

  request                  = Net::HTTP::Post.new(url)
  request["Content-Type"]  = "application/x-www-form-urlencoded"
  request["Authorization"] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
  request.body             = "grant_type=authorization_code&code=#{code}&redirect_uri=#{@redirect_uri}"

  https.request(request)
end

def refresh_token
  refresh_token = Database.get_value(@db_name, "refresh_token")
  url           = URI(@token_url)
  https         = Net::HTTP.new(url.host, url.port);
  https.use_ssl = true

  request                  = Net::HTTP::Post.new(url)
  request["Content-Type"]  = "application/x-www-form-urlencoded"
  request["Authorization"] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
  request.body             = "grant_type=refresh_token&refresh_token=#{refresh_token}"
  json = JSON.parse(https.request(request).body)
  Database.store(@db_name, {"access_token" => json["access_token"], "expires_at" => expires_at(json["expires_in"]) })
end

authorize unless Database.has_key?(@db_name, "access_token")

refresh_token if token_expired?(Database.get_value(@db_name, "expires_at"))

puts Database.get_value(@db_name, "expires_at")
puts Database.get_value(@db_name, "access_token")


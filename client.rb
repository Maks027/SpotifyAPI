# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'
require 'cgi'
require 'base64'

# Net/http utilities
class Client
  def self.init_client(uri, http_method)
    uri           = URI(uri)
    @https        = Net::HTTP.new(uri.host, uri.port)
    @https.use_ssl = true

    case http_method
    when 'get'  then Net::HTTP::Get.new(uri)
    when 'post' then Net::HTTP::Post.new(uri)
    end
  end

  def self.parse_body(params)
    case params.dig(:headers, :"Content-Type")
    when 'application/x-www-form-urlencoded'
      params[:payload].map { |parameter, value| "#{parameter}=#{value}" }.join('&')
    when 'application/json'
      params[:payload].to_json
    else
      params[:payload]
    end
  end

  def self.request(uri, params, http_method)
    request = init_client(uri, http_method)

    params[:headers]&.each { |header, content| request[header] = content }
    request.body = parse_body(params) if params[:payload]

    raw_response = @https.request(request)
    begin
      params[:preparsed] ? JSON.parse(raw_response.response.body) : raw_response
    rescue JSON::ParserError
      raw_response
    end
  end

  def self.post(uri, params)
    request(uri, params, 'post')
  end

  def self.get(uri, params)
    request(uri, params, 'get')
  end
end

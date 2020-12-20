require 'sinatra/base'
require_relative 'database'

class Server < Sinatra::Base
  get '/callback' do
    Database.store("access", { "code" => params[:code] })
    params[:code]
  end
end
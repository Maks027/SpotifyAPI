require 'cgi'
require 'uri'
require "net/http"
require 'pry'
require 'json'

@search_url = "https://api.spotify.com/v1/search"

@access_token = "Bearer BQBG8A8p2e7_Qh-8PZfMldd7oFm9Hc6L2o9E3l5tr0ZufWszJrl1nUEXGAWCATI9kV1T1tRAyMCFxU8QU8ubGGREXd-tyOEik3KiRdbqOnLreJs65J06nf3CkUV52ldK7DzihjSJGKyckRlOKTBZ8PLIKjqIrsQ6UwAqWlpF6lClr7GOSCA_qkE-WtZybIs3HxC0SUg9oQnuQQ"


file = File.open("tracklists/PandoraBox_tracklist.json")
json = JSON.parse(file.read)

def search_track(name, artists)
  artists_str  = artists.length > 1 ? artists.join(" ") : artists.first
  search_query = "artist:#{artists_str} track:#{name}".gsub(" ", "%20")

  url = URI("#{@search_url}?q=#{search_query}&type=track&limit=1")
  https = Net::HTTP.new(url.host, url.port);
  https.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request["Authorization"] = @access_token

  response      = https.request(request)
  json_response = JSON.parse(response.body)
  spotify_url   = json_response["tracks"]["items"][0]["external_urls"]["spotify"]

  # json_response["tracks"]["items"][0]["id"]
rescue
end

json.each do |track|
  puts search_track(track["trackName"], track["artists"])
end

binding.pry

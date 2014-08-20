require 'sinatra'
require 'json'
load './twitter_helper.rb'

get '/tweets' do
  results = Tweets.search(params)
  
  return {
    latitude:   params[:lat], 
    longitude:  params[:lng],
    time:       params[:time],
    tweets:     results
  }.to_json
end

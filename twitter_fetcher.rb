require 'sinatra'
require 'json'
load './twitter_helper.rb'

get '/tweets' do
  tweets = Tweets.search(params)
  
  return {
    latitude:   params[:lat], 
    longitude:  params[:lng],
    time:       params[:time],
    tweets:     tweets
  }.to_json
end

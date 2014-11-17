require 'sinatra'
require 'json'
load './twitter_query.rb'

get '/tweets' do

  tweets = TwitterQuery.search(params)
  
  return {
    latitude:   params[:lat], 
    longitude:  params[:lng],
    time:       params[:time],
    tweets:     tweets
  }.to_json

end

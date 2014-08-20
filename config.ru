require './twitter_fetcher'

if development?
  require 'dotenv'
  Dotenv.load
end

run Sinatra::Application
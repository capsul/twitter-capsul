require './twitter_fetcher'

if development?
  require 'dotenv'
  Dotenv.load
end

$stdout.sync = true

run Sinatra::Application

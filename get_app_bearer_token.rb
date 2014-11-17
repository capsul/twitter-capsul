require 'httparty'
require 'base64'

class Twitter
  include HTTParty
 
  base_uri  'https://api.twitter.com'
  format    :json
end

c_key    = ENV['TWITTER_CAPSUL2_CONSUMER_KEY']
c_secret = ENV['TWITTER_CAPSUL2_CONSUMER_SECRET']

c_key = c_key
c_secret = c_secret
c_key_secret = "#{c_key}:#{c_secret}"
p c_key_secret
encoded_c_key_secret = Base64.strict_encode64(c_key_secret)
p encoded_c_key_secret
p ENV['ENCODED_C_KEY_SECRET']


headers = 
{
  'Authorization' => "Basic #{encoded_c_key_secret}", 
  'Content-Type'  => "application/x-www-form-urlencoded;charset=UTF-8"
}

p headers

body = 'grant_type=client_credentials'

response = Twitter.post('/oauth2/token', :body => body, :headers => headers)

if response.code == 200
	p response
  bearer_token = response['access_token']
  p bearer_token
else
  p response
  puts "[ERROR] Something's gone terribly wrong"
end


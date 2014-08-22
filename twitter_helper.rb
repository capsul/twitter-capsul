require 'httparty'
require 'twitter'
require 'json'

module Tweets
  def self.search params = {}
    twitter_fetcher = TwitterFetcher.new
    twitter_fetcher.search_tweets params
  end

  class TwitterFetcher
    def search_tweets params = {}
      client = config_client
      puts params

      tweets = client.search("",
        geocode: params['lat'] + "," + 
                 params['lng'] + "," + 
                 ".5mi",
        :until => params['time'],
        result_type: 'mixed',
        count: 40,
        include_entities: true 
        ).map do |tweet|
          tweet_to_granual tweet
        end
      clean_response tweets
    end
    
    private
    def config_client args = {}
      client = Twitter::REST::Client.new do |config|
        config.consumer_key         = ENV['CONSUMER_KEY']
        config.consumer_secret      = ENV['CONSUMER_SECRET']
        config.access_token         = ENV['ACCESS_TOKEN']
        config.access_token_secret  = ENV['ACCESS_SECRET']
      end
    end

    def clean_response tweets
      filtered_tweets = filter_duplicates tweets
      sort_hash_by_type filtered_tweets, "id"
    end

    def filter_duplicates tweets
      tweets.uniq { |tweet| [tweet[:author] ].join(":") }
    end

    def sort_hash_by_type tweets, type
      tweets.sort_by { |key| key[type].to_i } 
    end

    def tweet_to_granual tweet
      return {
        type:       'text',
        id:         tweet.id.to_s,
        created_at: tweet.created_at,
        source:     'twitter',
        language:   tweet.lang,
        content:    tweet.text,
        author:     tweet.user.screen_name,
        location:   location(tweet),
        hashtags:   hashtags(tweet),
      }
    end

    def location tweet
      {
        latitude:   tweet.geo.coordinates[0].to_s,
        longitude:  tweet.geo.coordinates[1].to_s
      }
    end

    def hashtags tweet
      tweet.hashtags.map { |hashtag| hashtag.text }
    end
  end
end
require 'httparty'
require 'date'
require 'time'

module TwitterQuery

  def self.search params = {}
    twitter_search = TwitterSearch.new params
    twitter_search.request
  end

  class TwitterSearch
    include HTTParty
    base_uri 'https://api.twitter.com/1.1/search/tweets.json?'
    format    :json

    attr_reader :app_bearer_token, :headers, :params, :avg_ids_per_sec, :beacon, :search_offsets

    def initialize params = {}
      @app_bearer_token = ENV['APP_AUTH_BEARER_TOKEN']
      @headers          = { 'Authorization' => "Bearer #{app_bearer_token}", 
                            'Accept-Encoding' => "gzip, deflate" }
      @params           = params
      @avg_ids_per_sec  = 4194250000
      # offsets in seconds before midnight for: midnight, 9:30pm, 3:30pm, 9am
      @search_offsets   = [0, 9000, 30600, 54000]
      # query twitter api with 'until:' at geolocation to get one latest-in-day tweet to use as beacon
      @beacon = self.class.get("q=until%3A#{next_day}&geocode=#{params['lat']}%2C#{params['lng']}%2C0.5km&result_type=mixed&count=1", :headers => headers)
      @timezone_max_id  = nil
    end

    def request

      tweets = []

      search_offsets.each do |offset|
        offset_id = timezone_max_id - (avg_ids_per_sec * offset)
        response = self.class.get("q=%20&geocode=#{params['lat']}%2C#{params['lng']}%2C0.5km&result_type=mixed&count=100&max_id=#{offset_id}", :headers => headers)
        tweets += response.parsed_response['statuses'].map { |tweet| tweet_to_granule tweet }
      end

      filter_tweets tweets

    end

    private

    def day_requested
      DateTime.strptime((params['time'].to_i + params['utc_offset'].to_i).to_s,'%s').to_s.split("T")[0]
    end

    def next_day
      Date.parse(day_requested).next.to_s
    end

    def beacon_id
      beacon.parsed_response['statuses'][0]['id_str'].to_i
    end

    def beacon_time
      DateTime.parse(beacon.parsed_response['statuses'][0]['created_at']).to_time.to_i
    end

    def midnight_gmt
      midnight_gmt = DateTime.parse(next_day + "T00:00:00-0000").to_time.to_i
    end

    def timezone_max_id
      @timezone_max_id || calc_timezone_max_id
    end

    def calc_timezone_max_id
      # twitter 'until:' is coarse and timezone insensitive.
      # We'll use the beacon's 'created_at' and 'id_str' to infer a 'max-id' that roughly 
      # coincides with timezone-accurate midnight at the location we're searching for.
      beacon_midnight_offset  = midnight_gmt - beacon_time
      gmt_midnight_id         = beacon_id + (avg_ids_per_sec * beacon_midnight_offset)
      timezone_offset         = params['utc_offset'].to_i
      @timezone_max_id        = gmt_midnight_id - (avg_ids_per_sec * timezone_offset)
    end

    def filter_tweets tweets

      earlyTimestamp = DateTime.parse(day_requested + "T00:00:00-0000").to_time.to_i - params['utc_offset'].to_i
      lateTimestamp = DateTime.parse(next_day + "T00:00:00-0000").to_time.to_i - params['utc_offset'].to_i

      tweets.delete_if do |tweet| 
        # filter retweets
        tweet[:content][0,4] == 'RT @' ||

        # filter out of bounds times
        tweet[:created_at].to_i < earlyTimestamp ||
        tweet[:created_at].to_i > lateTimestamp
      end

      # filter duplicate content
      tweets.uniq { |tweet| tweet[:content] }
      # one to a customer
      # tweets.uniq { |tweet| tweet[:author] }

    end

    def tweet_to_granule tweet
      return {
        type:       'text',
        id:         tweet['id_str'],
        created_at: DateTime.parse(tweet['created_at']).to_time.to_i.to_s,
        source:     'twitter',
        language:   tweet['lang'],
        content:    tweet['text'],
        author:     tweet['user']['screen_name'],
        location:   location(tweet),
        hashtags:   hashtags(tweet),
      }
    end

    def location tweet
      if tweet['geo']
        {
          latitude:   tweet['geo']['coordinates'][0].to_s,
          longitude:  tweet['geo']['coordinates'][1].to_s
        }
      else
        {
          latitude:   params['lat'],
          longitude:  params['lng']
        }
      end
    end

    def hashtags tweet
      if tweet['entities']['hashtags']
        tweet['entities']['hashtags'].map { |hashtag| hashtag['text'] }
      else
        []
      end
    end

  end

end

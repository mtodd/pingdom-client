require File.join(File.dirname(__FILE__), '..', 'pingdom-client') unless defined? Pingdom

module Pingdom
  class Client
    
    attr_accessor :limit
    
    def initialize(options = {})
      @options = options.with_indifferent_access
      @connection = Faraday::Connection.new(:url => "https://api/pingdom.com/api/2.0/") do |builder|
        builder.url_prefix = "https://api.pingdom.com/api/2.0"
        
        builder.adapter :logger, @options[:logger]
        
        builder.adapter :excon
        
        # builder.use Gzip # TODO: write GZip response handler, add Accept-Encoding: gzip header
        builder.response :yajl
        builder.use Tinder::FaradayResponse::WithIndifferentAccess
        
        builder.basic_auth @options[:username], @options[:password]
      end
    end
    
    # probes => [1,2,3] #=> probes => "1,2,3"
    def prepare_params(options)
      options.each do |(key, value)|
        options[key] = Array.wrap(value).map(&:to_s).join(',')
        options[key] = value.to_i if value.acts_like?(:time)
      end
      
      options
    end
    
    def get(uri, params = {}, &block)
      response = @connection.get(@connection.build_url(uri, prepare_params(params)), &block)
      update_limits!(response.headers['req-limit-short'], response.headers['req-limit-long'])
      response
    end
    
    def update_limits!(short, long)
      @limit ||= {}
      @limit[:short]  = parse_limit(short)
      @limit[:long]   = parse_limit(long)
      @limit
    end
    
    # "Remaining: 394 Time until reset: 3589"
    def parse_limit(limit)
      if limit.to_s =~ /Remaining: (\d+) Time until reset: (\d+)/
        { :remaining => $1.to_i,
          :resets_at => $2.to_i.seconds.from_now }
      end
    end
    
    def test!(options = {})
      Result.parse(self, get("single", options)).first
    end
    
    def checks(options = {})
      Check.parse(self, get("checks", options))
    end
    def check(id)
      Check.parse(self, get("checks/#{id}")).first
    end
    
    # Check ID
    def results(id, options = {})
      options.reverse_merge!(:includeanalysis => true)
      Result.parse(self, get("results/#{id}", options))
    end
    
    def probes(options = {})
      Probe.parse(self, get("probes", options))
    end
    
    def contacts(options = {})
      Contact.parse(self, get("contacts", options))
    end
    
    def summary(id)
      Summary.proxy(self, id)
    end
    
  end
end

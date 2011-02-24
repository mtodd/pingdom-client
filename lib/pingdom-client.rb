require 'faraday'

require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/time/acts_like'
require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash/slice'

LOGGER = lambda do |app|
  lambda do |env|
    puts "Request: %s %s" % [env[:method], env[:url].to_s]
    app.call(env)
  end
end

module Pingdom
  class Client
    
    attr_accessor :limit
    
    def initialize(credentials = {})
      @connection = Faraday::Connection.new(:url => "https://api/pingdom.com/api/2.0/") do |builder|
        builder.url_prefix = "https://api.pingdom.com/api/2.0"
        
        builder.builder.run LOGGER
        
        builder.adapter :excon
        
        # builder.use Gzip # TODO: write GZip response handler, add Accept-Encoding: gzip header
        builder.response :yajl
        builder.use Tinder::FaradayResponse::WithIndifferentAccess
        
        builder.basic_auth credentials[:username], credentials[:password]
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
      Check.parse(self, get("checks/#{id}"))
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
  
  class Base
    def initialize(client, response, attributes = {})
      @client     = client
      @response   = response
      @attributes = attributes
    end
    
    def self.attributes(hash)
      hash.each do |(attribute, aliases)|
        class_eval <<-"end;" unless instance_methods.include?(attribute.to_s)
          def #{attribute}
            @attributes[:#{attribute}]
          end
        end;
        
        Array.wrap(aliases).each do |aliased|
          alias_method aliased, attribute
        end
      end
    end
    
    def method_missing(name, *args, &block)
      @attributes[name] or super
    end
    
    def respond_to?(name)
      super(name) || @attributes.key?(name)
    end
    
    def id
      @attributes[:id]
    end
    
    def inspect
      "#<%s %s>" % [self.class.to_s, @attributes.inject([]){ |a, (k,v)| a << "%s: %s" % [k,v.inspect]; a }.join(' ')]
    end
    
    def self.check_error!(response)
      if response.body.key?(:error)
        raise Error, "%s (%s %s)" % [ response.body[:error][:errormessage],
                                      response.body[:error][:statuscode],
                                      response.body[:error][:statusdesc] ]
      end
    end
    
    def self.parse(client, response)
      check_error!(response)
      response.body
    end
  end
  
  # {"statusdesclong"=>"OK", "probeid"=>28, "responsetime"=>221, "statusdesc"=>"OK", "status"=>"up", "probedesc"=>"Amsterdam 2, Netherlands"}
  class Result < Base
    def self.parse(client, response)
      results = super
      Array.wrap(results[:results] || results[:result]).map do |result|
        new(client, response, result)
      end
    end
    
    attributes  :responsetime => :response_time,
                :probeid      => :probe_id
    
    def probe
      @client.probes.detect{ |probe| probe.id == probe_id }
    end
  end
  
  # {"name"=>"Autocomplete", "id"=>259103, "type"=>"http", "lastresponsetime"=>203173, "status"=>"up", "lasttesttime"=>1298102416}
  class Check < Base
    def self.parse(client, response)
      super[:checks].map do |check|
        new(client, response, check)
      end
    end
    
    attributes  :lastresponsetime => :last_response_time,
                :lasttesttime     => :last_test_time,
                :lasterrortime    => :last_error_time
    
    def results(options = {})
      @client.results(id, options)
    end
    
    def summary
      @client.summary(id)
    end
    
    def lasttesttime
      Time.at(super)
    end
    
    def lasterrortime
      Time.at(super)
    end
    
  end
  
  # {"city"=>"Manchester", "name"=>"Manchester, UK", "country"=>"United Kingdom",
  # "countryiso"=>"GB", "id"=>46, "ip"=>"212.84.74.156", "hostname"=>"s424.pingdom.com", "active"=>true}
  class Probe < Base
    def self.parse(client, response)
      super[:probes].map do |probe|
        new(client, response, probe)
      end
    end
    
    attributes :countryiso => [:country_iso, :country_code]
    
    def test!(options)
      @client.test!(options.merge(:probeid => id))
    end
    
  end
  
  # {"name"=>"Larry Bernstein", "directtwitter"=>false, "id"=>142762, "cellphone"=>"1-510-501-7401",
  # "paused"=>false, "defaultsmsprovider"=>"clickatell", "email"=>"lbernstein@demandbase.com"}
  class Contact < Base
    def self.parse(client, response)
      super[:contacts].map do |contact|
        new(client, response, contact)
      end
    end
    
    attributes :cellphone => :phone
    
  end
  
  class Summary < Base
    
    class Proxy < Struct.new(:client, :check_id)
      def average(options = {})
        options.reverse_merge!(:byprobe => true, :includeuptime => true)
        Average.parse(client, client.get("summary.average/#{check_id}", options))
      end
      alias_method :averages, :average
      
      def outage(options = {})
        options.reverse_merge!(:byprobe => true, :includeuptime => true)
        Outage.parse(client, client.get("summary.outage/#{check_id}", options))
      end
      alias_method :outages, :outage
      
      def performance(options = {})
        options.reverse_merge!(:resolution => :day, :includeuptime => true)
        Performance.parse(client, client.get("summary.performance/#{check_id}", options))
      end
    end
    
    def self.proxy(client, check)
      Proxy.new(client, check)
    end
    
    def from
      Time.at(@attributes[:from])
    end
    
    def to
      Time.at(@attributes[:to])
    end
    
    attributes :responsetime => :response_time
    
    # summary.average includeuptime probes=34,35 byprobe
    # { "responsetime"=>{
    #     "from"=>0, "to"=>1298110456, "probes"=>"34, 35", "avgresponse"=>[
    #       {"probeid"=>35, "avgresponse"=>94},
    #       {"probeid"=>34, "avgresponse"=>125} ]},
    #   "status"=>{"totalup"=>5035757, "totalunknown"=>1293069551, "totaldown"=>5078}}
    class Average < Base
      def self.parse(client, response)
        body  = super[:summary]
        sum   = body[:responsetime]
        attrs = sum.slice(:from, :to)
        attrs[:probes] = (attrs[:probes] || "").gsub(/\w+/, '').split(',').map{|e| e.to_i }
        
        sum[:status] = Status.new(client, response, body[:status]) if body.key?(:status)
        
        case sum[:avgresponse]
        when Array
          sum[:responsetime]   = 0
          sum[:averages]  =
          sum.delete(:avgresponse).map do |avg|
            sum[:responsetime] += avg[:avgresponse]
            new(client, response, avg)
          end
          sum[:responsetime] = sum[:responsetime] / sum[:averages].size if sum[:averages].size > 0
          
        when Integer
          sum[:responsetime] = sum.delete(:avgresponse)
          
        end
        
        sum = Summary.new(client, response, sum)
      end
      
      attributes :probeid => :probe_id
      
      def probe
        @client.probes.detect{ |probe| probe.id == probe_id }
      end
      
    end
    
    # summary.outage
    # {"states"=>[{"timeto"=>1297587576, "timefrom"=>1297475316, "status"=>"up"},
    #             {"timeto"=>1297587906, "timefrom"=>1297587576, "status"=>"down"},
    #             {"timeto"=>1298110749, "timefrom"=>1297587906, "status"=>"up"}]}
    class Outage < Base
      def self.parse(client, response)
        super[:summary][:states].
        select{ |s| s[:status] == "down" }.
        map do |outage|
          new(client, response, outage)
        end
      end
      
      def downtime
        (@attributes[:timeto] - @attributes[:timefrom]).seconds
      end
      
      def timefrom
        Time.at(@attributes[:timefrom])
      end
      
      def timeto
        Time.at(@attributes[:timeto])
      end
      
      attributes  :timefrom => [:time_from, :from],
                  :timeto   => [:time_to, :to,]
      
    end
    
    # summary.performance includeuptime resolution=day
    # {"days"=>[{"unmonitored"=>0, "downtime"=>0, "starttime"=>1297238400, "uptime"=>86400, "avgresponse"=>234},
    #           {"unmonitored"=>0, "downtime"=>0, "starttime"=>1297324800, "uptime"=>86400, "avgresponse"=>215},
    #           {"unmonitored"=>0, "downtime"=>2648, "starttime"=>1297411200, "uptime"=>83752, "avgresponse"=>211},
    #           {"unmonitored"=>0, "downtime"=>0, "starttime"=>1297497600, "uptime"=>86400, "avgresponse"=>207},
    #           {"unmonitored"=>0, "downtime"=>330, "starttime"=>1297584000, "uptime"=>86070, "avgresponse"=>228},
    #           {"unmonitored"=>0, "downtime"=>0, "starttime"=>1297670400, "uptime"=>86400, "avgresponse"=>236},
    #           {"unmonitored"=>0, "downtime"=>0, "starttime"=>1297756800, "uptime"=>86400, "avgresponse"=>230},
    #           {"unmonitored"=>0, "downtime"=>0, "starttime"=>1297843200, "uptime"=>86400, "avgresponse"=>256},
    #           {"unmonitored"=>0, "downtime"=>0, "starttime"=>1297929600, "uptime"=>86400, "avgresponse"=>216},
    #           {"unmonitored"=>0, "downtime"=>0, "starttime"=>1298016000, "uptime"=>86400, "avgresponse"=>251},
    #           {"unmonitored"=>0, "downtime"=>0, "starttime"=>1298102400, "uptime"=>8646, "avgresponse"=>223}]}
    class Performance < Base
      INTERVALS = {
        "hour"  => 1.hour,
        "day"   => 1.day,
        "week"  => 1.week
      }
      
      def self.parse(client, response)
        body      = super[:summary]
        interval  = body.keys.detect{ |k| INTERVALS.keys.include?(k.chomp('s').to_s) }.chomp('s').to_sym
        intervals = body[interval]
        
        intervals.map do |perf|
          perf[:interval] = interval
          new(client, response, perf)
        end
      end
      
      def starttime
        Time.at(@attributes[:starttime])
      end
      
      def endtime
        starttime + INTERVALS[interval.to_s].to_i
      end
      alias_method :end_at, :endtime
      
      def uptime
        @attributes[:uptime].seconds
      end
      def downtime
        @attributes[:downtime].seconds
      end
      def unmonitored
        @attributes[:unmonitored].seconds
      end
      def monitored
        uptime + downtime
      end
      def period
        monitored + unmonitored
      end
      
    end
    
    # {"status"=>{"totalup"=>5035757, "totalunknown"=>1293069551, "totaldown"=>5078}}
    class Status < Base
    end
    
  end
  
  class Error < RuntimeError
  end
end

# Taken from:
# https://github.com/collectiveidea/tinder/raw/master/lib/tinder/middleware.rb
# See:
# https://github.com/collectiveidea/tinder/blob/master/MIT-LICENSE
module Tinder
  module FaradayResponse
    class WithIndifferentAccess < ::Faraday::Response::Middleware
      begin
        require 'active_support/core_ext/hash/indifferent_access'
      rescue LoadError, NameError => error
        self.load_error = error
      end

      def self.register_on_complete(env)
        env[:response].on_complete do |response|
          json = response[:body]
          if json.is_a?(Hash)
            response[:body] = ::HashWithIndifferentAccess.new(json)
          elsif json.is_a?(Array) and json.first.is_a?(Hash)
            response[:body] = json.map{|item| ::HashWithIndifferentAccess.new(item) }
          end
        end
      end
    end

    class RaiseOnAuthenticationFailure < ::Faraday::Response::Middleware
      def self.register_on_complete(env)
        env[:response].on_complete do |response|
          raise AuthenticationFailed if response[:status] == 401
        end
      end
    end
  end
end

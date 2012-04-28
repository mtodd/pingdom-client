module Pingdom
  
  # {"name"=>"Autocomplete", "id"=>259103, "type"=>"http", "lastresponsetime"=>203173, "status"=>"up", "lasttesttime"=>1298102416}
  class Check < Base
    def self.parse(client, response)
      checks = super
      Array.wrap(checks[:checks] || checks[:check]).map do |check|
        new(client, response, check)
      end
    end
    
    attributes  :lastresponsetime => :last_response_time,
                :lasttesttime     => :last_test_time,
                :lasterrortime    => :last_error_time
    
    def results(options = {})
      @client.results(id, options)
    end
    
    def paused(bool)
      @client.paused(id, bool)
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
  
end

module Pingdom
  
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
    
    # {"status"=>{"totalup"=>5035757, "totalunknown"=>1293069551, "totaldown"=>5078}}
    class Status < Base
    end
    
  end
  
end

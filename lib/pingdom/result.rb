module Pingdom
  
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
  
end

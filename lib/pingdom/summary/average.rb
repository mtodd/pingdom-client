module Pingdom
  class Summary
    
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
      
      attributes  :probeid      => :probe_id,
                  :responsetime => :response_time
      
      def probe
        @client.probes.detect{ |probe| probe.id == probe_id }
      end
      
    end
    
  end
end

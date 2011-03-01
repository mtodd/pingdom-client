module Pingdom
  class Summary
    
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
    
  end
end

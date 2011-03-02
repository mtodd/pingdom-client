module Pingdom
  class Summary
    
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
        intervals = body[interval.to_s.pluralize]
        
        intervals.map do |perf|
          perf[:interval] = interval
          new(client, response, perf)
        end
      end
      
      def starttime
        Time.at(@attributes[:starttime])
      end
      alias_method :start_at, :starttime
      
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
      
      attributes :avgresponse => :response_time
      
    end
    
  end
end

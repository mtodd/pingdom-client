module Pingdom

  # {"id"=>259103, "timefirsttest"=>203173, "timeconfirmtest"=>1298102416}
  class Analysis < Base
    def self.parse(client, response)
      analysis = super
      Array.wrap(analysis[:analysis]).map do |analysis_element|
        new(client, response, analysis_element)
      end
    end

    attributes  :timefirsttest    => :time_start,
                :timeconfirmtest  => :time_confirm
  end
end
module Pingdom
  
  class RCA < Base
    def self.parse(client, response)
      rca = super
      new(client, response, rca)
    end
  end  
end
module Pingdom
  
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
  
end

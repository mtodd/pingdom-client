module Pingdom
  
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
  
end

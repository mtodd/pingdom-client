module Pingdom
  class Base
    
    def initialize(client, response, attributes = {})
      @client     = client
      @response   = response
      @attributes = attributes
    end
    
    def self.attributes(hash)
      hash.each do |(attribute, aliases)|
        class_eval <<-"end;" unless instance_methods.include?(attribute.to_s)
          def #{attribute}
            @attributes[:#{attribute}]
          end
        end;
        
        Array.wrap(aliases).each do |aliased|
          alias_method aliased, attribute
        end
      end
    end
    
    def method_missing(name, *args, &block)
      @attributes[name] or super
    end
    
    def respond_to?(name)
      super(name) || @attributes.key?(name)
    end
    
    def id
      @attributes[:id]
    end
    
    def inspect
      "#<%s %s>" % [self.class.to_s, @attributes.inject([]){ |a, (k,v)| a << "%s: %s" % [k,v.inspect]; a }.join(' ')]
    end
    
    def self.check_error!(response)
      if response.body.key?(:error)
        raise Error, "%s (%s %s)" % [ response.body[:error][:errormessage],
                                      response.body[:error][:statuscode],
                                      response.body[:error][:statusdesc] ]
      end
    end
    
    def self.parse(client, response)
      check_error!(response)
      response.body
    end
    
  end
end

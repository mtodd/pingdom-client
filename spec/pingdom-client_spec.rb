require 'spec_helper'

describe Pingdom::Client do
  let(:client){ Pingdom::Client.new(CREDENTIALS) }
  
  describe "#test!" do
    it "should test a single endpoint" do
      response = client.test!(:host => "pingdom.com", :type => "http")
      
      response.status.should == "up"
      response.responsetime.should be_a(Numeric)
    end
  end
  
  describe "#checks" do
    it "should get a list of checks" do
      checks = client.checks
      
      first = checks.first
      first.should be_a(Pingdom::Check)
      first.last_response_time.should be_a(Numeric)
    end
  end
  
  describe "#limit" do
    { :short  => "short term",
      :long   => "long term" }.each do |(key, label)|
      describe label do
        let(:limit){ client.test!(:host => "pingdom.com", :type => "http"); client.limit[key] }
        
        it "should indicate how many requests can be made" do
          limit[:remaining].should be_a(Numeric)
        end
        
        it "should indicate when the current limit will be reset" do
          limit[:resets_at].acts_like?(:time).should be_true
        end
      end
    end
  end
  
end

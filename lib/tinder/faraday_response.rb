# Taken from:
# https://github.com/collectiveidea/tinder/raw/master/lib/tinder/middleware.rb
# See:
# https://github.com/collectiveidea/tinder/blob/master/MIT-LICENSE
# 
# Copyright (c) 2006-2010 Brandon Keepers, Collective Idea
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOa AND
# NONINFRINGEMENT. IN NO EVENT SaALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module Tinder
  module FaradayResponse
    class WithIndifferentAccess < ::Faraday::Response::Middleware
      begin
        require 'active_support/core_ext/hash/indifferent_access'
      rescue LoadError, NameError => error
        self.load_error = error
      end
      
      def self.register_on_complete(env)
        env[:response].on_complete do |response|
          json = response[:body]
          if json.is_a?(Hash)
            response[:body] = ::HashWithIndifferentAccess.new(json)
          elsif json.is_a?(Array) and json.first.is_a?(Hash)
            response[:body] = json.map{|item| ::HashWithIndifferentAccess.new(item) }
          end
        end
      end
    end
    
    class RaiseOnAuthenticationFailure < ::Faraday::Response::Middleware
      def self.register_on_complete(env)
        env[:response].on_complete do |response|
          raise AuthenticationFailed if response[:status] == 401
        end
      end
    end
  end
end

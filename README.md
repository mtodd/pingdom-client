# Pingdom RESTful API Client

Pingdom RESTful API wrapper for Ruby.

NOTE: This is a 3rd party gem and not an official product from Pingdom.

## Usage

    client = Pingdom::Client.new :username => u, :password => p, :key => k
    check = client.checks.first #=> #<Pingdom::Check>
    check.last_response_time    #=> 200 (ms)
    check.status                #=> "up"

    result = check.results.first(:probes => [1,2,3], :status => [:up, :down])
                                #=> #<Pingdom::Result>
    result.status               #=> :up
    result.up?                  #=> true
    result.response_time        #=> 20000 (microsecs)

    avg = check.summary.average(:from   => 1.month.ago,
                                :probes => [1,2,3])
                                #=> #<Pingdom::Summary::Average>
    avg.response_time           #=> 200 (ms)
    probe_avg = avg.averages.first
    probe_avg.response_time     #=> 120 (ms)
    probe_avg.probe.name        #=> "Atlanta, GA"

## Contributors

* Updated for Ruby 1.9.x/2.0.0 by Jason Straughan ([jdstraughan](http://github.com/jdstraughan))
* Emily Price ([duien](http://github.com/duien))
* Based on [pingom-client](https://github.com/mtodd/pingdom-client) by [Matt Todd](https://github.com/mtodd)

## License

The MIT License

Copyright (c) 2013 Jason Straughan.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

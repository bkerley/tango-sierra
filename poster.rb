require 'pp'
require 'json'
require 'date'
require 'httparty'


datum = {time: DateTime.now.iso8601,
  kevin: rand(1000),
  steve: rand(1000),
  brad: "b#{'e' * rand(100)}s"
 }

puts data = [datum].to_json

pp HTTParty.post 'http://tango-sierra.dev/collections/bryce', body: data, content_type: 'text/json'

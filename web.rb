require 'riak'
require 'sinatra'
require 'date'
require 'json'
require './lib/merger'

CLIENT = Riak::Client.new pb_port: 17017
DAY_BUCKET = CLIENT.bucket 'tango-sierra-day'
Merger.supervise_as :merger

helpers do
  def merger
    Celluloid::Actor[:merger]
  end
end

set :show_exceptions, false

error do
  e = env['sinatra.error']
  { 
    error: e.inspect,
    backtrace: e.backtrace
  }.to_json
end

get '/' do
  'tango sierra'
end

post '/collections/:collection_name' do
  cn = params[:collection_name]
  unparsed_data = request.body.read
  data = JSON.parse unparsed_data

  days = Hash.new

  data.each do |datum|
    time = DateTime.iso8601 datum['time']
    
    stamp = time.to_date.iso8601

    day_list = days[stamp] || []

    offset = time.to_time.to_f - time.to_date.to_time.to_f
    datum.delete 'time'
    datum['offset'] = offset.to_f

    day_list << datum

    days[stamp] = day_list
  end

  days.each do |k,v|
    blob = DAY_BUCKET.new k
    blob.data = v
    blob.content_type = 'application/json'
    blob.store
  end

  merger.enqueue days.keys

  days.values.flatten.length.to_s
end

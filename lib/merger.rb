require 'celluloid'
require 'set'
require 'pp'

class Merger
  include Celluloid
  def initialize
    @queue = Set.new
  end

  def enqueue(*keys)
    @queue.merge *keys

    async.flush
  end

  def flush
    first = @queue.first
    return if first.nil?

    obj = DAY_BUCKET.get first
    if obj.conflict?
      merged = obj.siblings.inject do |rolling, current|
        $stderr.puts rolling.data.pretty_inspect
        $stderr.puts current.data.pretty_inspect
        a1 = rolling.data
        a2 = current.data
        
        merged = a1 + a2

        raise "failed merge #{first} didn't know types" unless merged.is_a? Array
        
        sorted = merged.sort_by{ |e| e['offset'] }.uniq

        rolling.data = sorted
        rolling
      end

      obj.siblings = [merged.dup]
      obj.store
    end

    @queue.delete first

    async.flush
  end
end

require 'forwardable'

module Librato
  # collects and stores measurement values over time so they can be
  # reported periodically to the Metrics service
  #
  class Collector
    extend Forwardable

    def_delegators :counters, :increment
    def_delegators :aggregate, :measure, :timing

    attr_reader :tags

    def initialize(options={})
      @tags = options[:tags]
    end

    # access to internal aggregator object
    def aggregate
      @aggregator_cache ||= Aggregator.new(prefix: @prefix, default_tags: @tags)
    end

    # access to internal counters object
    def counters
      @counter_cache ||= CounterCache.new(default_tags: @tags)
    end

    # remove any accumulated but unsent metrics
    def delete_all
      aggregate.delete_all
      counters.delete_all
    end
    alias :clear :delete_all

    def group(prefix)
      group = Group.new(self, prefix)
      yield group
    end

    # update prefix
    def prefix=(new_prefix)
      @prefix = new_prefix
      aggregate.prefix = @prefix
    end

    def prefix
      @prefix
    end

  end
end

require_relative 'collector/aggregator'
require_relative 'collector/counter_cache'
require_relative 'collector/exceptions'
require_relative 'collector/group'

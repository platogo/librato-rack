require 'test_helper'
require 'rack/test'

# Tests for universal tracking for all request paths
#
class RequestTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('test/apps/basic.ru').first
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
  end

  def test_increment_total_and_status
    get '/'
    assert last_response.ok?
    assert_equal 1, counters["rack.request.total"]
    assert_equal 1, counters["rack.request.status.200"]
    assert_equal 1, counters["rack.request.status.2xx"]

    get '/status/204'
    assert_equal 2, counters["rack.request.total"]
    assert_equal 1, counters["rack.request.status.200"], 'should not increment'
    assert_equal 1, counters["rack.request.status.204"], 'should increment'
    assert_equal 2, counters["rack.request.status.2xx"]
  end

  def test_request_times
    get '/'

    # common for all paths
    assert_equal 1, aggregate["rack.request.time"][:count],
      'should track total request time'

    # status specific
    assert_equal 1, aggregate["rack.request.status.200.time"][:count]
    assert_equal 1, aggregate["rack.request.status.2xx.time"][:count]
  end

  def test_track_exceptions
    begin
      get '/exception'
    rescue RuntimeError => e
      raise unless e.message == 'exception raised!'
    end
    assert_equal 1, counters["rack.request.exceptions"]
  end


  private

  def aggregate
    Librato.collector.aggregate
  end

  def counters
    Librato.collector.counters
  end

  #
  #
  #   test 'track slow requests' do
  #     visit slow_path
  #     assert_equal 1, counters["rails.request.slow"]
  #   end

end
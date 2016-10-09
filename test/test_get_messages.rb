require 'minitest'
require 'minitest/autorun'
require 'minitest/benchmark'
require 'httpclient'
require 'multi_json'

load_arr = []
load_arr.each do |lib|
        require File.expand_path(File.dirname(__FILE__)+"/"+lib)
end

# Test cases for 'GET /messages' endpoint
class TestGetMessages < Minitest::Test
        def setup
		@httpclint = HTTPClient.new
        end

        def test_get_messages
		url = "http://localhost:7777/messages"
		response = @httpclint.get(url)
		status_code = response.status
		body = response.body
		message_id_array = MultiJson.load(body)
		# check status code
		assert_equal(200, status_code)	
		# check body
		assert_equal(true, (message_id_array.is_a?(Array)))	
		# check id
		assert_equal(true, (message_id_array[0].is_a?(Hash))) if message_id_array[0]
	end

end

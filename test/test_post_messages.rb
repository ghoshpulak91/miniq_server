require 'minitest'
require 'minitest/autorun'
require 'minitest/benchmark'
require 'httpclient'
require 'multi_json'

load_arr = []
load_arr.each do |lib|
        require File.expand_path(File.dirname(__FILE__)+"/"+lib)
end

# Test cases for 'POST /messages/{queue}' endpoint
class TestPostMessages < Minitest::Test
        def setup
		@httpclint = HTTPClient.new
        end

        def test_post_messages
		base_url = "http://localhost:7777/messages/test"
		header = {"Content-Type" => "application/json"}
		json_data = '{"msg": "Stayzilla"}'
		message_info_hash_from_json_data = MultiJson.load(json_data)
		response = @httpclint.post(base_url, json_data, header)
		status_code = response.status
		body = response.body
		message_info_hash = MultiJson.load(body)
		
		# check status code
		assert_equal(201, status_code)	
		
		# check message id 
		id = message_info_hash["id"]
		assert_equal(true, (id and not id.empty?))
	end

end

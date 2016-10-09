require 'minitest'
require 'minitest/autorun'
require 'minitest/benchmark'
require 'httpclient'
require 'multi_json'

load_arr = []
load_arr.each do |lib|
        require File.expand_path(File.dirname(__FILE__)+"/"+lib)
end

# Test cases for 'POST /messages' endpoint
class TestPostMessages < Minitest::Test
        def setup
		@httpclint = HTTPClient.new
        end

        def test_post_messages_valid_json_data_only_required_fields
		base_url = "http://localhost:7777/messages"
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
		
		# check msg  
		msg = message_info_hash["msg"]
		assert_equal(true, (msg and not msg.empty?))
		
		# check processing
		processing = message_info_hash["processing"]
		assert_equal(false, processing)
	end

end

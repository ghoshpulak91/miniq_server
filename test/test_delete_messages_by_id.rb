require 'minitest'
require 'minitest/autorun'
require 'minitest/benchmark'
require 'httpclient'
require 'multi_json'

load_arr = []
load_arr.each do |lib|
        require File.expand_path(File.dirname(__FILE__)+"/"+lib)
end

# This is a test case for 'DELETE /messages/{id}' endpoint
class TestDeleteMessagesByID < Minitest::Test
        def setup
		@httpclint = HTTPClient.new
        end

        def test_delete_messages_by_id
		base_url = "http://localhost:7777/messages"
		header = {"Content-Type" => "application/json"}
		json_data = '{"msg": "Stayzilla"}'
		response = @httpclint.post(base_url, json_data, header)
		status_code = response.status
		# check status code
		assert_equal(201, status_code)	
		
		response = @httpclint.get(base_url)
		status_code = response.status
		# check status code
		assert_equal(200, status_code)	
		body = response.body
		message_id_array = MultiJson.load(body)
		message_id = message_id_array[0]["id"]
		assert_equal(true, (message_id and not message_id.empty?))
		
		url = base_url + "/" + message_id
		response = @httpclint.get(url)
		status_code = response.status
		# check status code
		assert_equal(200, status_code)	
		
		response = @httpclint.delete(url)
		status_code = response.status
		# check status code
		assert_equal(200, status_code)	
		
		response = @httpclint.get(url)
		status_code = response.status
		# check status code
		assert_equal(404, status_code)	
	end
        
        def test_delete_messages_by_id_invalid_id
		url = "http://localhost:7777/messages/100001"
		response = @httpclint.delete(url)
		status_code = response.status
		# check status code
		assert_equal(404, status_code)	
	end

end

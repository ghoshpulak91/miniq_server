require 'sinatra'

load_arr=["./lib/miniq.rb", "./lib/logger.rb"]
load_arr.each do |lib|
	require File.expand_path(File.dirname(__FILE__)+"/"+lib)
end

set :public_folder, File.dirname(__FILE__) + './public'
set :miniq, MiniQ.new


# below are the all routes i.e. API end-points 

# POST /messages/{queue} - Add a new message into a queue
#
# Request POST /messages/{queueu}
#   The body is a JSON object based on the JSON schema can be found in post-messages-request.json .
# Response 
#   Valid status codes:
#     201 Created if the message was successfully added
#     400 Bad request if any mandatory fields were missing or if the input JSON was invalid
#   The body is a JSON object based on the JSON schema can be found in post-messages-response.json.
post '/messages/:queue' do
	request.body.rewind  # in case someone already read it
	body = request.body.read
	response = settings.miniq.post_messages(params, body)
	set_response(response)
end

# GET /messages/{queue} - List all messages need to be processed from a queue
# 
# Request GET /messages/{queue}
#   Empty body.
# Response
#   Valid status codes:
#     200 OK
#   The body is a JSON array based on the JSON schema can be found in get-messages-response.json. Only messages need to be processed should be returned.
get '/messages/:queue' do
	response = settings.miniq.get_messages(params)
	set_response(response)
end

# GET /messages/{queue}/{id} - Get details on a specific message by id
# 
# Request GET /messages/{queue}/{id}
#   Empty body.
# Response
#   Valid status codes:
#     200 OK if the message exists
#     404 Not found if the message does not exist
#   A 404 Not found is expected when the message does not exist. Messages with processing set to false should be returned with a 200 OK.
#   The response body for a 200 OK request can be found in get-messages-id-response.json(TODO).
get '/messages/:queue/:id' do 
	response = settings.miniq.get_message_by_id(params)
	set_response(response)
end

# DELETE /messages/{queue}/{id} - Delete a message by id. This implements notify option in MiniQ
# 
# Request DELETE /messages/{queue}/{id}
#   Empty body
# Response
#   Valid status codes:
#     200 OK if the message has been removed
#     404 Not found if the message didn't exist
#   Empty body expected.
delete '/messages/:queue/:id' do 
	response = settings.miniq.delete_message_by_id(params)
	set_response(response)
end

# If you hit a page which is not implemented yet.
not_found do
	$log.info "API Page not found, params #{params}"
	response = settings.miniq.get_response_hash(404)
	set_response(response)
end

# If unhandled exception occurred
error do
	status_code = env['sinatra.error'].http_status.to_i
	$log.info "Sorry there was a error - " + env['sinatra.error'].message + " for params #{params}. status code is #{status_code}"
	response = settings.miniq.get_response_hash(status_code)
	set_response(response)
end

# To set response 
# @param [Hash] response a hash contains status, content_type and body
def set_response(response = {})
	status(response[:status])
	content_type(response[:content_type], {charset: 'utf-8'}) if response[:content_type]
	body(response[:body]) if response[:body]
end

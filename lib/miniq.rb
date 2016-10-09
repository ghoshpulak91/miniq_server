require 'json'
require 'multi_json'
require 'monitor'
require 'json-schema'

load_arr = ["./logger.rb", "./db/mongodb.rb"]
load_arr.each do |lib|
	require File.expand_path(File.dirname(__FILE__)+"/"+lib)
end

# This class implemets all methods, which validates input and save input to the databases 
class MiniQ
	# a monitor is an object or module intended to be used safely by more than one thread.
	include MonitorMixin

	def initialize(args_hash = {})
		@db_name = "MiniQDB"
		@collection_name = "messages"
		@processing_timeout = 10 # secs
		@mongodb_obj = DB::MongoDB.new(@db_name)
		load_all_json_schemas
	end

	# It lodas all json-schema files, pasre into Hash and save in a instance variable @all_json_schemas
	def load_all_json_schemas
		json_schema_dir = get_json_schema_dir
		@all_json_schemas = {}
		Dir.glob(json_schema_dir+"/*").each do |json_schema_file_name|
			$log.info "json_schema_file_name: #{json_schema_file_name}"
			schema_name = File.basename(json_schema_file_name)
			$log.info "schema_name: #{schema_name}"
			begin
				schema = MultiJson.load(File.open(json_schema_file_name).read)
				@all_json_schemas[schema_name] = schema
			rescue Exception => e
				$log.error "#{e.class}:#{e.message} for json_schema_file_name: #{json_schema_file_name}"
				$log.info e.backtrace
			end
		end
		$log.info "all_json_schemas: #{@all_json_schemas}"
	end
	
	# It determines the path for json-schema directory
	def get_json_schema_dir
		File.expand_path(File.dirname(__FILE__)+"/"+"./json_schema")
	end

	# This make a response hash 
	# @param [Integer] status returned status code 
	# @param [Hash] body_hash returned body hash
	# @return [Hash] return a response_hash. Keys are status, content_type and body.
	def get_response_hash(status, body_hash=nil)
		body = nil
		body = JSON.pretty_generate(body_hash) if body_hash
		response_hash = {
			status: status, 
			content_type: "application/json", 
			body: body
		}
		$log.info "response_hash: #{response_hash}"
		return response_hash
	end

	# This prase message info input josn and validates as per json-schema.
	# Then add default fields added and visible
	# @pram [String] message_info_json a json string as input 
	# @return [Hash] validated message_info_hash
	def parse_and_validate_message_info_json(message_info_json)
		$log.info "message_info_json: #{message_info_json}" 
		message_info_hash = nil
		begin
			message_info_hash = MultiJson.load(message_info_json)
			JSON::Validator.validate!(@all_json_schemas['post-messages-request.json'], message_info_hash)
		rescue Exception => e
			$log.error "#{e.class}:#{e.message} for message_info_json: #{message_info_json}, message_info_hash: #{message_info_hash}"
			$log.info e.backtrace
			return nil
		end
		message_info_hash["published_at"] = Time.now.utc.to_i
		message_info_hash["processing"] = false
		#message_info_hash["processing_started_at"] = nil
		return message_info_hash	
	end

	# This method implemets 'POST /messages' endpoint
	# @param [Hash] params request parameter hash
	# @param [String] body json input string
	# @return [Hash] return a response_hash. Keys are status, content_type and body.
	def post_messages(params={}, body=nil)
		$log.info "params: #{params}"
		$log.info "body: #{body}"
		message_info_json = body 
		message_info_hash = parse_and_validate_message_info_json(message_info_json)	
		return get_response_hash(400) if not message_info_hash
		begin
			document_id = @mongodb_obj.insert_one_document_into_a_collection(@collection_name, message_info_hash)
			raise Exception.new("could not save message_info_hash") if not (document_id and document_id.is_a?(BSON::ObjectId))
			message_info_hash["id"] = document_id.to_s
			JSON::Validator.validate!(@all_json_schemas['post-messages-response.json'], message_info_hash)
			return get_response_hash(201, message_info_hash) 
		rescue Exception => e
			$log.error "#{e.class} -> #{e.message} for params #{params} and body: #{body}"
			$log.info e.backtrace
			return get_response_hash(500)
		end
	end

	# This method implemets 'GET /messages' endpoint
	# @param [Hash] params request parameter hash
	# @return [Hash] return a response_hash. Keys are status, content_type and body.
	def get_messages(params = {})
		message_info_hash_array = []
		begin
			refresh_messages
			filter = { "processing" => false }
			processing_started_at = Time.now.utc.to_i
			query  = { :processing => true, :processing_started_at => processing_started_at }
			update_query  = { '$set' => query }
			@mongodb_obj.find_and_update_documents_in_a_collection(@collection_name, filter, update_query)
			@mongodb_obj.get_documents_from_a_collection(@collection_name, query).each do |message_document|
				message_info_hash = {}
				message_document.each do |key, val|
					if key == "_id"
						message_info_hash["id"] = val.to_s
					else
						message_info_hash[key] = val
					end
				end
				message_info_hash_array << message_info_hash
			end
			JSON::Validator.validate!(@all_json_schemas['get-messages-response.json'], message_info_hash_array)
			return get_response_hash(200, message_info_hash_array)
		rescue Exception => e
			$log.error "#{e.class} -> #{e.message} for params #{params}"
			$log.info e.backtrace
			return get_response_hash(500)
		end
	end

	def refresh_messages()
		filter = { :processing => true, :processing_started_at => {'$lte' => (Time.now.utc.to_i - @processing_timeout )}  }
		query  =  { '$set' =>  { :processing => false, :processing_started_at => nil } }
		@mongodb_obj.find_and_update_documents_in_a_collection(@collection_name, filter, query)
	end
	
	# This method implemets 'GET /messages/{id}' endpoint
	# @param [Hash] params request parameter hash. Key is 'id'
	# @return [Hash] return a response_hash. Keys are status, content_type and body.
	def get_message_by_id(params = {})
		message_info_hash = {}
		begin
			id = params["id"]
			query_hash = {
				:_id => BSON::ObjectId(id)
			}
			message_document = @mongodb_obj.get_documents_from_a_collection(@collection_name, query_hash, :limit => 1).first
			return get_response_hash(404) if not message_document
			message_document.each do |key, val|
				if key == "_id"
					message_info_hash["id"] = val.to_s
				else
					message_info_hash[key] = val
				end
			end
			#JSON::Validator.validate!(@all_json_schemas['get-messages-id-response.json'], message_info_hash)
			return get_response_hash(200, message_info_hash)
		rescue BSON::ObjectId::Invalid => e
			return get_response_hash(404)
		rescue Exception => e
			$log.error "#{e.class} -> #{e.message} for params #{params}"
			$log.info e.backtrace
			return get_response_hash(500)
		end
	end
	
	# This method implemets 'DELETE /messages/{id}' endpoint
	# @param [Hash] params request parameter hash. Key is 'id'
	# @return [Hash] return a response_hash. Keys are status, content_type and body.
	def delete_message_by_id(params = {})
		message_info_hash = {}
		begin
			id = params["id"]
			query_hash = {
				:_id => BSON::ObjectId(id)
			}
			message_document = @mongodb_obj.delete_a_documents_from_a_collection(@collection_name, query_hash)
			return get_response_hash(404) if not message_document.is_a?(BSON::Document)
			return get_response_hash(200)
		rescue BSON::ObjectId::Invalid => e
			return get_response_hash(404)
		rescue Exception => e
			$log.error "#{e.class} -> #{e.message} for params #{params}"
			$log.info e.backtrace
			return get_response_hash(500)
		end
	end
end

# miniq_server: This is MiniQ server using Sinatra, Ruby and MongoDB

Overview
========
Have a look at Amazon's Simple Queuing System: http://goo.gl/Bn8qaD . MiniQ is similar, but simpler system. It is a broker that allows multiple producers to write to it, and multiple consumers to read from it. It runs on a single server. Whenever a producer writes to MiniQ, a message ID is generated and returned as confirmation. Whenever a consumer polls MiniQ for new messages, it gets those messages which are NOT processed by any other consumer that may be concurrently accessing MiniQ. NOTE that, when a consumer gets a set of messages, it must notify MiniQ that it has processed each message (individually). This deletes that message from the MiniQ database. If a message is received by a consumer, but NOT marked as processed within a configurable amount of time, the message then becomes available to any consumer requesting again.

This is server part and it is REST API. It support following requests:

 - `POST /messages/{queue}` - Add a new message into a queue
 - `GET /messages/{queue}` - List all messages need to be processed from a queue
 - `GET /messages/{queue}/{id}` - Get details of a specific message by id
 - `DELETE /messages/{queue}/{id}` - Delete a message by id. This implements notify option in MiniQ

API specification
=================

Add a new message into a queue
------------------------------

### Request `POST /messages/{queue}`

The body is a JSON object based on the JSON schema can be found in `post-messages-request.json` .

post-messages-request.json

~~~
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "POST /messages/queue [request]",
  "description": "Add a new message to the MiniQ",
  "type": "object",
  "required": [
    "msg"
  ],
  "additionalProperties": false,
  "properties": {
    "msg": {
      "type": "string",
      "description": "String message max 16000000 bytes",
      "maxLength": 16000000
    }
  }
}
~~~

### Response

Valid status codes:

 - `201 Created` if the message was successfully added
 - `400 Bad request` if any mandatory fields were missing or if the input JSON was invalid

The body is a JSON object based on the JSON schema can be found in `post-messages-response.json`.

post-messages-response.json

~~~
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "POST /messages/queue [response]",
  "description": "Response after adding a new message to the MiniQ",
  "type": "object",
  "required": [
    "id"
  ],
  "additionalProperties": false,
  "properties": {
    "id": {
      "type": "string",
      "description": "Object id from the database"
    }
  }
}
~~~

List all messages need to be processed from a queue
--------------------------------------------------

### Request `GET /messages/{queue}`

Empty body.

### Response

Valid status codes:

 - `200 OK`

The body is a JSON array based on the JSON schema can be found in `get-messages-response.json`. Only messages need to be processed should be returned.

get-messages-response.json

~~~
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "GET /messages/queue [response]",
  "description": "List all messages to be processed",
  "type": "array",
  "additionalProperties": false,
  "items": {
    "type": "object",
    "description": "Message object",
    "uniqueItems": true
  }
}
~~~

Get details of a specific message by id
---------------------------------------

### Request `GET /messages/{queue}/{id}`

Empty body.

### Response

Valid status codes:

 - `200 OK` if the message exists
 - `404 Not found` if the message does not exist

A `404 Not found` is expected when the message does not exist. Messages with `processing` set to `false` should be returned with a `200 OK`.

The response body for a `200 OK` request can be found in `get-messages-id-response.json`(TODO).

Delete a message by id. This implements notify option in MiniQ
--------------------------------------------------------------

### Request `DELETE /messages/{queue}/{id}`

Empty body

### Response

Valid status codes:

 - `200 OK` if the message has been removed
 - `404 Not found` if the message didn't exist

Empty body expected.

Setup and build details
=======================

------

## Language 

Ruby version - 2.3.1

------

## Web framework 

Sinatra version - 1.4.7 

------

## Database 

Mongodb version - 3.2.9 

------

## Getting started

1) Clone or download this repository

~~~
$ git clone https://github.com/ghoshpulak91/miniq_server.git
$ cd miniq_server
~~~

2) Install prerequisites and setting up environment.

2.1) Install mongodb(Ref: https://docs.mongodb.com/manual/installation/).

2.2) Install RVM and Ruby-2.3.1(Ref: http://tecadmin.net/install-ruby-on-rails-on-ubuntu/)

2.3) Set ruby-2.3.1 as default ruby version. 

~~~
$ rvm use 2.3.1 --default
$ ruby --version
~~~


2.4) Install required gems 

~~~ 
$ gem install bundler sinatra thin mongo yaml json multi_json logger monitor json-schema httpclient minitest 
~~~

------

## Run the application 

To start 

~~~
$ ./start 
~~~

The application can be started in localhost at port number 7777. To test click [here](http://localhost:7777) or run below command.

~~~
$ curl http://localhost:7777
~~~

To stop 

~~~
$ ./stop 
~~~

------

## Check logs 

Log file path  

~~~
$ ./log/run.log 
~~~

If you are using Linux then you can use bellow command to check log  

~~~
$ tail -f ./log/run.log
~~~

------

## Run test suite 

To run the test suite 

~~~
$ ruby ./test/test_post_messages.rb
$ ruby ./test/test_get_messages.rb
$ ruby ./test/test_delete_messages_by_id.rb
~~~ 

Scaling this service 
====================

### How to scale this service to meet high volume requests? What infrastructure/stack would we use and why?

To scale this service, we will have to scale two main component mongodb and REST API.

Vertical scaling
----------------

We can add more power(CPU, RAM) to those machines where mongodb and API is hosted. 

Horizontal scaling
------------------

Here we can use mongodb cluster. And for API we can use pool of machines under HAProxy and AWS auto-scalling.

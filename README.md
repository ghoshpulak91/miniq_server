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

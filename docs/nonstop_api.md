# Nonstop API

We are talking `HTTP + SSE + JSON`.

You will receive information by subscribing to `/downstream`, an EventSource based stream.

You can request information by `POST`ing your request to `/inbox`.

To receive private information you must provide a private channel authorization token as a get parameter like `/downstream?private_channel_auth=abc123`.

All your requests to us most provide a valid **Hashcash** to be accepted.

	client                 ~ internet ~                endpoint
	|                                                         |
	|                                                         |
	| GET /downstream?hashcash=…&private_channel_auth=abc123  |
	|========================================================>|
	|<========================================================|
	|                                                         |
	|                                                         |
	| POST /inbox                                             |
	| X-Hashcash: …                                           |
	|                                                         |
	| { "json": "…" }                                         |
	|-------------------------------------------------------->|
	|                                                         |
	|                                                         |
	| POST /inbox                                             |
	| X-Hashcash: …                                           |
	| X-Auth: …                                               |
	|                                                         |
	| { "json": "…" }                                         |
	|-------------------------------------------------------->|
	|                                                         |
	


## Examples



## See it in action

## Hashcash

In order to talk to our endpoints you are obliged to provide a Hashcash for each request you do. This benefits service availability, since we can drop a lot of bad requests very early and cheaply.
We understand that this incurs implementation overhead on the client side. But we think that in the end it is worth it by providing a highly available service to you.

To help you implement a client, we provide you with code snippets in various languages and examples on how to calculate the Hashcash for a request.

The following example shows how to calculate the Hashcash in Javascript. Note that the implementation takes care to not block the user interface during calculation.

	function hashcash(string, difficulty, callback) {
	  var started = +(new Date),
	    random = Math.random(),
	    bitmask = parseInt(new Array(difficulty+1).join("0") + new Array(32-difficulty+1).join("1"), 2),
	    i = 0;
	  while ((CryptoJS.SHA1(string+random).words[0] | bitmask) != bitmask) {
	    if ((i+=1) % 100 == 0 && +(new Date) - started >= 50) {
	      setTimeout(function() { hashcash(string, difficulty, callback); }, 0);
	      return;
	    }
	    random = Math.random();
	  }
	  callback.call(this, random);
	};


## Authentication

## Reference


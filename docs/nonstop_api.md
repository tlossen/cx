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
	| X-Hash: …                                               |
	| X-Cash: …                                               |
	|                                                         |
	| { "json": "…" }                                         |
	|-------------------------------------------------------->|
	|                                                         |
	|                                                         |
	| POST /inbox                                             |
	| X-Hash: …                                               |
	| X-Cash: …                                               |
	| X-Auth: …                                               |
	|                                                         |
	| { "json": "…" }                                         |
	|-------------------------------------------------------->|
	|                                                         |
	


## Examples

## See it in action

## Real client ip

To calculate the Hashcash for our endpoints you always need to know your real client ip.
If you cannot obtain this information by yourself, you can rely on our real ip service.
Simply ask an endpoint:

	GET /ip

	GET /ip.js

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

## Register a new user

1. Request to create a new account:

		timestamp = TIMESTAMP()
		pass = SHA256( password )
		hash = real_client_ip + timestamp + request_body + nonce
		cash = HASHCASH_256( hash, difficulty=20 )
		
		POST /inbox
		X-Hash: hash
		X-Cash: cash
	
		{"create":"account","email":"joe.doe@gmail.com","pass":pass}

2. The users E-Mail will be verified by a verification link
3. Once the user has successfully verfied his E-Mail, the account will be available

## E-Mail verification

1. The user visits the site with a special get parameter
2. The site picks up the parameter and Requests verification:

		timestamp = TIMESTAMP()
		hash = real_client_ip + timestamp + request_body + nonce
		cash = HASHCASH_256( hash, difficulty=20 )

		POST /inbox
		X-Hash: hash
		X-Cash: cash
		
		{"verify":verification_token}

3. If this request returns as `202 Accepted` the user can continue to log in

## Private Channel

	private_channel_token = SHA256( login + SHA256 ( password ) )
	timestamp = TIMESTAMP()
	nonce = RANDOM()
	hash = real_client_ip + timestamp + private_channel_token + nonce
	cash = HASHCASH_SHA256( hash, difficulty=20 )

	GET /downstream
		?private_channel_token=ee6a8a7802609d9fffb48564a498557a7a48fae088c1290e65bed8a4231bece0
		&nonce=0.2989434872288257
		&hash=127.0.0.11368049279ee6a8a7802609d9fffb48564a498557a7a48fae088c1290e65bed8a4231bece00.22220543352887034
		&cash=000008312edb37b235b4404c0e1c8e0ae6e06bd21ddffdb7b8dbc74d10f97f7e


## Auth Token for Requests

1. Connect to your private channel
2. Listen for `set:auth_token` events
3. Request an auth_token:
		
		timestamp = TIMESTAMP()
		hash = real_client_ip + timestamp + request_body + nonce
		cash = HASHCASH_256( hash, difficulty=20 )

		POST /inbox
		X-Hash: hash
		X-Cash: cash
		
		{"get":"auth_token"}

4. You will receive a new auth token via your private channel as an `set:auth_token` event with data like `{"token":"…","expires_at":1234567890}`

Those tokens expire over time. You can check the token expiry by yourself. If a token is expired, you will immediately be noticed via an `expire:auth_token` event or your requests fail with `401 Unauthorized`.
You can generate a new token any time.

## POSTing any authorized request

	timestamp = TIMESTAMP()
	hash = real_client_ip + timestamp + request_body + auth_token + nonce
	cash = HASHCASH_256( hash, difficulty=15 )

	POST /inbox
	X-Hash: hash
	X-Cash: cash
	X-Auth: auth_token
	
	{"cancel":"order","order_id":123}


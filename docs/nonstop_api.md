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

For Javascript we provide a url `GET /ip.js` for a `<script>` tag. Its response sets a global variable like `var REAL_CLIENT_IP = "127.0.0.1"`.

## UTC Timestamp

All timestamps you must be in UTC seconds since epoch.
In Javascript this can be achieved by applying the timezone offset:

	var d = new Date();
	var utc_timestamp = Math.floor((d.getTime() + d.getTimezoneOffset() * 60 * 1000) / 1000);

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
	  while ((CryptoJS.SHA256(string+random).words[0] | bitmask) != bitmask) {
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

		timestamp = TIMESTAMP_UTC()
		pass = SHA256( password )
		request_body_hash = SHA256( request_body )
		hash = real_client_ip + timestamp + request_body_hash + nons
		cash = HASHCASH_256( hash, difficulty=20 )
		
		POST /inbox
		X-Time: timestamp
		X-Nons: nons
		X-Cash: cash
	
		{"create":"account","email":"joe.doe@gmail.com","pass":pass}

2. The users E-Mail will be verified by a verification link
3. Once the user has successfully verfied his E-Mail, the account will be available

## E-Mail verification

1. The user visits the site with a special get parameter `?verify=verification_token`
2. The site picks up the parameter and requests verification:

		timestamp = TIMESTAMP_UTC()
		request_body_hash = SHA256( request_body )
		hash = real_client_ip + timestamp + request_body_hash + nons
		cash = HASHCASH_256( hash, difficulty=20 )

		POST /inbox
		X-Time: timestamp
		X-Nons: request_body_hash
		X-Cash: cash
		
		{"verify":verification_token}

3. If this request returns as `202 Accepted` the user can continue to log in

## Public Channel only

	timestamp = TIMESTAMP_UTC()
	nons = RANDOM()
	hash = real_client_ip + timestamp + nons
	cash = HASHCASH_SHA256( hash, difficulty=20 )
	
	GET /downstream
		?timestamp=1368049279
		&nons=0.07533829286694527
		&cash=00000098d141bb0d6efe311a30fe2a9bcf3062c2a313db721b771c6c50a9c613

## Public + Private Channel

	private_channel_token = SHA256( login + SHA256 ( password ) )
	timestamp = TIMESTAMP_UTC()
	nons = RANDOM()
	hash = real_client_ip + timestamp + private_channel_token + nons
	cash = HASHCASH_SHA256( hash, difficulty=20 )

	GET /downstream
		?private_channel_token=ee6a8a7802609d9fffb48564a498557a7a48fae088c1290e65bed8a4231bece0
		&timestamp=1368049279
		&nons=0.2989434872288257
		&cash=000008312edb37b235b4404c0e1c8e0ae6e06bd21ddffdb7b8dbc74d10f97f7e


## Auth Token for Requests

1. Connect to your private channel
2. Listen for `set:auth_token` events
3. Request an auth_token:
		
		timestamp = TIMESTAMP_UTC()
		request_body_hash = SHA256( request_body )
		hash = real_client_ip + timestamp + request_body_hash + nons
		cash = HASHCASH_256( hash, difficulty=20 )

		POST /inbox
		X-Time: timestamp
		X-Nons: nons
		X-Cash: cash
		
		{"get":"auth_token"}

4. You will receive a new auth token via your private channel as an `set:auth_token` event with data like `{"token":"…","expires_at":1234567890}`

Those tokens expire over time. You can check the token expiry by yourself. If a token is expired, you will immediately be noticed via an `expire:auth_token` event or your requests fail with `401 Unauthorized`.
You can generate a new token any time.

## POSTing any authorized request

	timestamp = TIMESTAMP_UTC()
	request_body_hash = SHA256( request_body )
	hash = real_client_ip + timestamp + auth_token + request_body_hash + nons
	cash = HASHCASH_256( hash, difficulty=15 )

	POST /inbox
	X-Time: timestamp
	X-Auth: auth_token
	X-Nons: nons
	X-Cash: cash
	
	{"cancel":"order","order_id":123}

## Exceptional Private Endpoints

In case public service unavailability we will issue private Endpoints as Subdomains by E-Mail to our registered active users.
If possible our public endpoint will respond with `503 Service Unavailable` during such an event. But it may not be reachable as well.
Using the private subdomain one can still access our full service. As a client application developer you could provide a facility to enter the private subdomain.

## Limitations and Banning

If you send a bunch of malformed requests to our endpoints you endanger yourself from having your ip banned temporarely.
Therefore please have an eye on the following limitations:

* `/inbox` accepts `POST` requests only
* The maximum request body length is `4k`
* The sum of the HTTP headers may not exceed `4k`
* Any given `timestamp` must not be older than `10s`
* No more than 3 unsuccessful authentication attempts within 1 hour
* No more than 1 invalid `hashcash`

A ban will block **all traffic** from your ip for several hours.
Be careful to not lock yourself out.

request = require 'request'
twit = require 'twit'

#
# the negotiator class handles direct twitter interaction - mainly, token exchange
# do not use it for anything other than token negotiation.
#
class negotiator
	constructor: ->
		@appTokens =
			consumer_key: new Buffer 'Y1M0bm9NWFNEWjh1a1VHU2djeFVR', 'base64'
			consumer_secret: new Buffer 'QjByblViRmVFUDkzMFdKaVdlcGZ5b1RYM1hVUVJ2UTFrVEVTWXFXNjg=', 'base64'
	getAuthUri: (fn) ->
		oauth =
			# has to be oob as per twitter docs
			callback: 'oob'
			consumer_key: @appTokens.consumer_key.toString()
			consumer_secret: @appTokens.consumer_secret.toString()

		request.post { url: 'https://api.twitter.com/oauth/request_token', oauth:oauth }, (err, res, body) ->
			if err
				debug 'crimson.getAuthUri err: ' + err
				return fn err
			tokens = qs.parse body

			if !tokens.oauth_callback_confirmed
				err = 'oauth_callback_confirmed return from twitter api as false'
				debug 'crimson.getAuthUri err: ' + err
				return fn err

			fn null, tokens.oauth_token, url.format {
				protocol: 'https'
				hostname: 'api.twitter.com'
				pathname: '/oauth/authorize'
				query:
					oauth_token: tokens.oauth_token
			}

	# pin will be used as the verifier, as per https://dev.twitter.com/docs/auth/pin-based-authorization
	tradePinForTokens: (token, pin, fn) ->
		oauth =
			consumer_key: @appTokens.consumer_key.toString()
			consumer_secret: @appTokens.consumer_secret.toString()
			token: token
			verifier: pin
		request.post { url: 'https://api.twitter.com/oauth/access_token', oauth:oauth }, (err, res, body) =>
			if err
				debug 'crimson.tradePinForTokens err: ' + err
				return fn err

			tokens = qs.parse body

			if !tokens.user_id
				err = 'No user_id received from twitter API - authentication failed?'
				debug 'crimson.tradePinForTokens err: ' + err
				return fn err

			# insert into users db
			@db.accounts.insert {
				token: tokens.oauth_token
				secret: tokens.oauth_token_secret
				userId: tokens.user_id
				enabled: true
			}, (err, doc) ->
				if err
					debug 'crimson.tradePinForTokens nedb err: ' + err
					return fn err
				fn null, doc

	# get a new twitter api instance (will provide streaming, etc.)
	getApi: (token, secret) ->
		return new twit({
			consumer_key: @appTokens.consumer_key.toString()
			consumer_secret: @appTokens.consumer_secret.toString()
			access_token: token
			access_token_secret: secret
		})

module.exports = negotiator

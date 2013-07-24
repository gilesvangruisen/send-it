express = require "express"
fs = require "fs"

app = express()
app.use express.logger()

requestsFile = fs.readFileSync 'requests.json'
requests = JSON.parse(requestsFile).requests

respondWith = {}

replaceDefaults = (response, replaceWith, returnWith) ->
	keys = Object.keys(response)
	for k in keys
		if (typeof response[k] is 'object') and (typeof replaceWith[k] is 'object')
			replaceDefaults response[k], replaceWith[k], returnWith
		else if (typeof response[k] is 'string') and (typeof replaceWith[k] is 'string')
			response[k] = replaceWith[k]
	return returnWith

doIt = (obj, request, response, paths) ->
	# split paths into array
	paths = paths.split(',')
	# check for parameters
	if Object.keys(request.params).length
		# if parameters, lets iterate through
		for key, value of request.params
			# iterate through paths
			for path in paths
				keyToMatch = path.substr(2, path.length-2)
				# check for match
				if key == keyToMatch
					num = paths.indexOf('/:'+keyToMatch)
					cases = requests
					# if path matches param key, iterate through to get the proper cases
					for i in [0..num]
						cases = cases[paths[i]]
					cases = cases['cases']
					# with cases, look for match with parameter value
					if typeof cases[key][request.params[key]] is 'object'
						cases = cases[key][request.params[key]]
						respondWith = obj['goodResponse']
						respondWith = replaceDefaults respondWith, cases, respondWith
					else
						respondWith = obj['badResponse']
				else
					# if not, something's wrong, return hard bad response
					respondWith = obj['badResponse']
	else
		# if not, return hard good response
		respondWith = obj['goodResponse']

	console.log "\n========================================================\n"
	console.log "REQUEST URL         : " + request.url
	console.log "REQUEST METHOD      : " + request.method
	console.log "REQUEST STATUS CODE : " + request.statusCode
	console.log "\n========================================================\n"

	response.send respondWith


sendItPost = (url, obj, paths) ->
	app.post url, (request, response) ->
		doIt obj, request, response, paths

sendItGet = (url, obj, paths) ->
	app.get url, (request, response) ->
		doIt obj, request, response, paths

buildPath = (obj, paths) ->
	keys = Object.keys obj
	len = keys.length
	ii = 0
	for k in keys
		v = obj[k]
		firstChar = k.substr 0,1
		if firstChar is '/'
			paths.push k
			buildPath v, paths
			paths.pop()
		else
			url = paths.join ''
			if k is 'get'
				sendItGet url, v, paths.join()
				console.log 'GET   ->  ' + url
				# console.log v
				console.log '------------------'
			else if k is 'post'
				sendItPost url, v, paths.join()
				console.log 'POST  ->  ' + url
				# console.log v
				console.log '------------------'

		if ii == len
			paths.pop()

		ii = ii + 1

paths = []
buildPath requests, paths

port = process.env.PORT || 5000
app.listen port, ->
	console.log "Listening on " + port

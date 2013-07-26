express = require "express"
fs = require "fs"

app = express()
app.use express.logger()

requestsFile = fs.readFileSync 'requests.json'
requests = JSON.parse(requestsFile).requests

respondWith = {}
globalTime = {}

clone = (obj) ->
	if Object::toString.call(obj) is "[object Array]"
		out = []
		i = 0
		len = obj.length
		while i < len
			out[i] = arguments.callee(obj[i])
			i++
		return out
	if typeof obj is "object"
		out = {}
		i = undefined
		for i of obj
			out[i] = arguments.callee(obj[i])
		return out
	obj

replaceDefaults = (response, replaceWith) ->
	keys = Object.keys(response)
	for k in keys
		if (typeof response[k] is 'object') and (typeof replaceWith[k] is 'object')
			replaceDefaults response[k], replaceWith[k]
		else if (typeof response[k] is 'string') and (typeof replaceWith[k] is 'string')
			response[k] = replaceWith[k]
	response

doIt = (obj, request, response, paths) ->
	# split paths into array
	# console.log request
	paths = paths.split(',')
	# check for parameters
	if Object.keys(request.params).length
		# if parameters, lets iterate through
		for key, value of request.params
			# iterate through paths
			for path in paths
				keyToMatch = null
				keyToMatch = path.substr(2, path.length-2)
				# check for match
				if key == keyToMatch
					num = paths.indexOf('/:'+keyToMatch)
					cases = null
					cases = clone(requests)
					# if path matches param key, iterate through to get the proper cases
					for i in [0..num]
						cases = cases[paths[i]]
					thisCase = cases['cases'][key][request.params[key]]
					# with cases, look for match with parameter value
					if thisCase isnt undefined
						# if match, check response type
						if typeof obj['success'] is 'object' and typeof thisCase is 'object'
							# if object, lets go through recursive replaceDefaults
							respondWith = clone(obj['success'])
							respondWith = replaceDefaults respondWith, thisCase
						else if ['string', 'boolean', 'number'].indexOf(typeof obj['success']) isnt -1
							# replace if string, even if thisCase is of diff type
							respondWith = clone(thisCase)
						else
							respondWith = clone(obj['success'])
					else
						respondWith = clone(obj['failure']) || "Invalid Request"
				else
					# if not, something's wrong, return hard bad response
					respondWith = clone(obj['failure']) || "Invalid Request"
	else
		# if not, return hard good response
		respondWith = clone(obj['success'])

	sendIt request, response, respondWith

sendIt = (request, response, respondWith) ->
	# SEEEENNNNDDDD IT
	response.send respondWith

	# calculate elapsed response time
	globalTime.end = new Date().getTime()
	elapsed = globalTime.end - globalTime.start

	# log some stuff that might be useful to see
	console.log "\n========================================================="
	console.log "======================   REQUEST   ======================"
	console.log "=========================================================\n"
	console.log "                METHOD : " + request.method
	console.log "                   URL : " + request.url
	console.log "           STATUS CODE : " + request.statusCode
	console.log "            PARAMETERS : "
	console.log request.params
	console.log "\n========================================================="
	console.log "======================   RESPONSE   ====================="
	console.log "=========================================================\n"
	console.log "          ELAPSED TIME : " + elapsed + "ms"
	console.log "         RESPONSE TYPE : " + typeof respondWith
	console.log "              RESPONSE : (below)"
	console.log respondWith
	console.log "\n========================================================="
	console.log "=========================================================\n"

receiveItPost = (url, obj, paths) ->
	app.post url, (request, response) ->
		globalTime.start = new Date().getTime()
		doIt obj, request, response, paths

receiveItGet = (url, obj, paths) ->
	app.get url, (request, response) ->
		globalTime.start = new Date().getTime()
		doIt obj, request, response, paths

buildPath = (obj, paths) ->
	keys = Object.keys obj
	len = keys.length
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
				receiveItGet url, v, paths.join()
				console.log '        GET   ->  ' + url
			else if k is 'post'
				receiveItPost url, v, paths.join()
				console.log '        POST  ->  ' + url

		if keys.indexOf(k) == len
			paths.pop()


paths = []

console.log "\n========================================================="
console.log "=======================   ROUTES   ======================"
console.log "=========================================================\n"
buildPath requests, paths
console.log "\n========================================================="
console.log "=========================================================\n"

port = process.env.PORT || 5000
app.listen port, ->

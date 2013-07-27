express = require "express"
cors = require "cors"
fs = require "fs"

app = express()
app.use express.logger()
app.use express.bodyParser()

# allow CORS
app.use cors()
app.use app.router

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
	if typeof response is 'object' and typeof replaceWith is 'object'
		for k in keys
			if (typeof response[k] is 'object') and (typeof replaceWith[k] is 'object')
				replaceDefaults response[k], replaceWith[k]
			else if (typeof response[k] is 'string') and (typeof replaceWith[k] is 'string')
				response[k] = replaceWith[k]
	else if ['string', 'boolean', 'number'].indexOf(typeof replaceWith) isnt -1
		response = replaceWith
	response

doIt = (obj, request, response, paths) ->
	if request.method is "POST"
		post = true
		get = false
		params = request.body
	else if request.method is "GET"
		post = false
		get = true
		params = request.params

	paths = paths.split(',')
	if Object.keys(params).length > 0
		cases = null
		cases = clone(requests)
		for i in [0...paths.length]
			cases = cases[paths[i]]
		responseTemplates = cases[request.method.toLowerCase()]
		cases = cases['cases']
		paramKeys = Object.keys params
		caseKeys = Object.keys cases
		for parKey in paramKeys
			if typeof cases[parKey] isnt 'undefined'
				keyOptionsForCaseKey = Object.keys cases[parKey]
				if keyOptionsForCaseKey.indexOf(params[parKey]) isnt -1
					thisCase = clone cases[parKey][params[parKey]]
					respondWith = clone(responseTemplates['success'])
					respondWith = replaceDefaults respondWith, thisCase
				else
					respondWith = responseTemplates['failure']
			else
				respondWith = responseTemplates['failure']
	else
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
	console.log request.body
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
				# cp = Object.keys v['cases']
				receiveItGet url, v, paths.join()
				console.log '        GET   ->  ' + url
			else if k is 'post'
				# cp = Object.keys v['cases']
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

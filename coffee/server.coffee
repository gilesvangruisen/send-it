express = require "express"
fs = require "fs"

app = express()
app.use express.logger()

requestsFile = fs.readFileSync 'requests.json'
requests = JSON.parse(requestsFile).requests

doIt = (obj, request, response) ->
	for key, value of request.params
		for spec, params of obj['cases'][key]
			if spec == value
				respondWith = obj['goodResponse']
				for param, val of obj['cases'][key][spec]
					respondWith[param] = val
				break
			else
				respondWith = obj['badResponse']

	console.log "\n========================================================\n"
	console.log "REQUEST URL         : " + request.url
	console.log "REQUEST METHOD      : " + request.method
	console.log "REQUEST STATUS CODE : " + request.statusCode
	console.log "\n========================================================\n"

	response.send respondWith

sendItPost = (url, obj) ->
	app.post url, (request, response) ->
		doIt obj, request, response

sendItGet = (url, obj) ->
	app.get url, (request, response) ->
		doIt obj, request, response

buildPath = (obj, url) ->
	for k, v of obj
		d = k.substr 0,1
		if d == '/'
			url = url + k
			buildPath(v,url)
		else if k is 'get'
			sendItGet(url, v)
		else if k is 'post'
			sendItPost(url, v)


buildPath(requests,'')

port = process.env.PORT || 5000
app.listen port, ->
	console.log "Listening on " + port
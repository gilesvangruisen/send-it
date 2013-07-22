#send-it

##what
send-it lets you define http requests and the responses they should yield. it's nifty for front-end testing as i can safely rely on my back-end to provide the appropriate responses in production, but don't want to make 'real' requests and create/manipulate/delete real data during testing. we also don't want to wait for every live request as it makes running tests horribly inefficient. so i built send-it lets you make mock requests to your own local server to speed up response time and alleviate that oh so terrible heartache of testing in a live environment
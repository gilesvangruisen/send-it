#send-it

##what
send-it lets you explicity define http requests and the responses they should yield.

##why
tl;dr I needed a fast, fake, locally run "api" for running tests with angular and karma
I built send-it because the JS library for our backend library (specifically [Kinvey](http://kinvey.com/)) does not play well with AngularJS's super cool $httpBackend service for hijacking HTTP requests. This means when we run tests, we're sending real requests to our backend API, albeit not our production app, but nevertheless real requests over the real internets. This resulted in our tests running incredibly inconsistently because we were throwing dozens of http requests to our backend in a matter of seconds. And that's not cool. The more requests, the longer they take, and the less likely they are to succeed. If our http requests fail, there's no way we can safely trust our tests to pass or fail as they are supposed to.

##how
With send-it, you explicitly define http requests in JSON format. They're in the form of groups and key value pairings. For example… I want to send a GET request to /user/login/:id, with :id being a variable for which I can define a number of cases. The request /user/login/:id has one response template, but depending on the value passed in place of :id, I can change the data of that template and send it back as a somewhat dynamic response.

#roadmap
I want to build this out to be more extensible. A few things I want:
* Build out cases and allow the use of reusable cases ([Rails fixtures are neat](http://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures))
* Allow you to define requests, cases, and responses in more formats than just JSON


##requests, cases, responses
It's all in requests.json. In the following example, I'm going to define requests and responses for a fake user API. There will be mock requests for getting a user (GET), and getting a list of users (GET). I'll add POST examples soon

    {
        "requests" : {
            "/users" : {
                "/:username" : {
                    "cases" : {
                        "username" : {
                            "giles" : {
                                "id" : "1",
                                "username" : "giles",
                                "email" : "giles@example.com"
                            },
                            "alex" : {
                                "id" : "1",
                                "username" : "giles",
                                "email" : "giles@example.com"
                            },
                            "matt" : {
                                "id" : "1",
                                "username" : "giles",
                                "email" : "giles@example.com"
                            },
                            "lulu" : {
                                "id" : "1",
                                "username" : "giles",
                                "email" : "giles@example.com"
                            }
                        }
                    },
                    "get" : {
                        "username" : {
                            "id" : ":id",
                            "username" : ":username",
                            "email" : ":email"
                        }
                    }
                },
                "get" : {
                    "success" : {
                        "users" : {
                            "giles" : {
                                "id" : "1",
                                "username" : "giles",
                                "email" : "giles@example.com"
                            },
                            "alex" : {
                                "id" : "2",
                                "username" : "alex",
                                "email" : "alex@example.com"
                            },
                            "matt" : {
                                "id" : "3",
                                "username" : "matt",
                                "email" : "matt@example.com"
                            },
                            "lulu" : {
                                "id" : "4",
                                "username" : "lulu",
                                "email" : "lulu@example.com"
                            }
                        }
                    }
                }
            }
        }
    }
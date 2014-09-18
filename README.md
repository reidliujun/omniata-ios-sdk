This branch is to support the multiple APIs and multiple Uids.

Take the analyzer service as an example, the formed url will be:
http://api.omniata.com/events?api_keys=<api_key1,api_key2>&uids=<uid1,uid2>

The initialize method of the new method is:

```objectivec
NSDictionary *user_info = @{
							//@"<api_key>" : @"<uid>",
                            @"a514370d" : @"iosTestingDevice", 
                            @"4a86cc2f" : @"iosTestingDevice2",
                            };
    
[iOmniataAPI initializeWithApiKeys:user_info AndDebug:TRUE];

```

Comments: it requires the backend support for parameters "api_keys" and "uids" in the url.



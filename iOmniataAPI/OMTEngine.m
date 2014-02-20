#import "OMTEngine.h"
#import "OMTQueue.h"
#import "Logger.h"
#import "OMTUtils.h"
#import "OMTEvent.h"
#import "OMTConfig.h"
#import "SBJson.h"

@implementation OMTEngine {
    
}

- (BOOL)initialize:(EventCallbackBlock) _eventCallback {
    offlineDetected = NO;
    
    eventCallback = _eventCallback;
    
    config = [OMTConfig instance];
    
    mEventQueue = [[OMTQueue alloc] init];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:EVENT_LOG_FILE_DIR];
    persistentEventQueue = [OMTQueue loadFromFile:[path stringByAppendingPathComponent:EVENT_LOG_FILE_NAME]];
    
    eventPersistThread = [[NSThread alloc] initWithTarget:self selector:@selector(persistEvents:) object:self];
    eventProcessorThread = [[NSThread alloc] initWithTarget:self selector:@selector(processEvents:) object:self];
    
    [eventPersistThread start];
    [eventProcessorThread start];
    
    return YES;
}

- (void)processEvents:(id)object {
    @autoreleasepool {
        while (![eventProcessorThread isCancelled]) {
            @autoreleasepool {
                [self uploadEvents];
            }
            [NSThread sleepForTimeInterval:EVENT_PROCESSOR_THREAD_DELAY];
        }
    }
}

- (void)uploadEvents {
    if (![self getConfig]) {
        LOG(SMT_LOG_VERBOSE, @"Upload skipped as Config is not loaded");
        return;
    }
    
    NSUInteger eventCount = [persistentEventQueue getCount];
    
    if (eventCount > 0) {
        if ([OMTUtils connectedToNetwork]) {
            
            // NOTE: disabled "batch" functionality since default batch size was always one
            NSMutableDictionary* event = [persistentEventQueue peek];

            // Clean parameters that must not be sent from event
            NSNumber *omCreationTime = [event objectForKey:@"om_creation_time"];
            if (omCreationTime != nil) {
                [event removeObjectForKey:@"om_creation_time"];
            }
            
            NSUInteger maxTries = config.maxRetriesForEvents;
            NSInteger responseCode = INTERNAL_SERVER_ERROR;
            NSString *response;
            
            NSUInteger numTries = 0;
            while (responseCode > HTTP_BAD_REQUEST && numTries < maxTries) {
                // Add (or replace) om_delta. Needs to be calculated separately for each retry, because it's function of time
                if (omCreationTime != nil) {
                    [event setObject:[NSNumber numberWithLong:([OMTUtils getCurrentTimeSecs] - [omCreationTime doubleValue])] forKey:@"om_delta"];
                }
                else {
                    // Backwards compatibility for old events in the queue that don't have om_creation_time.
                    // Obviously value of om_delta is > 0, but know way to calculate, so just using 0.
                    [event setObject:[NSNumber numberWithInt:0] forKey:@"om_delta"];
                }
                if (numTries > 0) {
                    [event setObject:[NSNumber numberWithInt:numTries] forKey:@"om_retry"];
                }
                
                NSMutableString *url = [NSMutableString stringWithString:[config getURL:SMT_SERVER_TRACK]];
                [url appendString:@"?"];
                [url appendString:[OMTUtils joinDictionaryByString:event :@"&"]];
                
                responseCode = [OMTUtils getFromURL:url:&response];
                
                if (responseCode > HTTP_BAD_REQUEST) {
                    [self notifyEventCallback:EVENT_FAILED NumTries:numTries];

                    numTries++;

                    NSUInteger sleep = SLEEP_TIME * pow(2, numTries);
                    if (sleep > MAX_SLEEP) {
                        sleep = MAX_SLEEP;
                    }

                    LOG(SMT_LOG_ERROR, @"Tracking event unsuccessful, will retry. Attempt: %d. Sleep %d", numTries, sleep);
                    [NSThread sleepForTimeInterval:sleep];
                }
                else {
                    [self notifyEventCallback:EVENT_SUCCESS NumTries:numTries];
                }
            }
            
            if (responseCode > HTTP_BAD_REQUEST) {
                LOG(SMT_LOG_ERROR, @"Discarding event");
                [self incrementDiscarded];
                [self notifyEventCallback:EVENT_DISCARDED NumTries:numTries];
            }
            
            [persistentEventQueue remove];
            [persistentEventQueue save];
        }
    }
}

- (void)setEventCallback:(EventCallbackBlock) _eventCallback {
    @synchronized(self) {
        self.eventCallback = _eventCallback;
    }
}

- (void)notifyEventCallback:(OMT_EVENT_STATUS) eventStatus NumTries:(NSUInteger)numTries {
    if (eventCallback != nil)
    {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            eventCallback(eventStatus, numTries);
        });
    }
}

/**
 * Increments in the persistent storage the total count of discarded events.
 */
- (void)incrementDiscarded {
    @synchronized(self) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:[userDefaults integerForKey:OM_DISCARDED] + 1 forKey:OM_DISCARDED];
    }
}

/**
 * Gets from the persistent storage the total count of discarded events.
 */
- (NSInteger)getDiscarded {
    @synchronized(self) {
        return [[NSUserDefaults standardUserDefaults] integerForKey:OM_DISCARDED];
    }
}

- (BOOL)getConfig {
    if (!eventConfigLoaded) {
        eventConfigLoaded = [config getEventConfig];
    }
    return eventConfigLoaded;
}

- (void)persistEvents:(id)object {
    @autoreleasepool {
        while(![eventPersistThread isCancelled]) {
            @autoreleasepool {
                NSUInteger eventCount = [mEventQueue getCount];
                if (eventCount > 0) {
                    for (NSInteger i = 0; i < eventCount; i++) {
                        OMTEvent *event = [mEventQueue remove];
                        [persistentEventQueue add:event.data];
                    }
                    
                    [persistentEventQueue save];
                        // TODO: not handling the response value
                }
            }
            [NSThread sleepForTimeInterval:EVENT_PERSIST_THREAD_DELAY];
        }
    }
}

- (BOOL)addEvent:(NSDictionary *)param {
    LOG(SMT_LOG_VERBOSE, @"Adding event to queue initiated...");
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:param];
    //double timeInSecs = [OMTUtils getCurrentTimeSecs];
    //[dic setObject:[NSString stringWithFormat:@"%.0f", timeInSecs] forKey:EVENT_POST_KEY_TIME];
    OMTEvent *event = [[OMTEvent alloc] initWithType:0 andData:dic];
    [mEventQueue add:event];
    LOG(SMT_LOG_VERBOSE, @"Successfully added Event to the queue");
    
    return YES;
}

- (void)dealloc {
    config = nil;
    mEventQueue = nil;
    persistentEventQueue = nil;
    eventProcessorThread = nil;
    eventPersistThread = nil;
}

@end
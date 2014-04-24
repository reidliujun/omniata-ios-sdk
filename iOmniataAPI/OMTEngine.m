#import "OMTEngine.h"
#import "OMTQueue.h"
#import "Logger.h"
#import "OMTUtils.h"
#import "OMTEvent.h"
#import "OMTConfig.h"
#import "OmSBJson.h"

@implementation OMTEngine {
    
}

- (BOOL)initialize:(EventCallbackBlock) _eventCallback {
    
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
        if (![OMTUtils connectedToNetwork]) {
            
            // Not connected to network, sleep and try again
            [NSThread sleepForTimeInterval:EVENT_PROCESSOR_RETRY_CONNECTIVITY_DELAY];
            
        } else {
        
            // NOTE: disabled "batch" functionality since default batch size was always one
            NSMutableDictionary* event = [persistentEventQueue peek];
            
            NSUInteger maxTries = config.maxRetriesForEvents;
            NSInteger responseCode;
            NSString *response;
            
            // Add (or replace) om_delta. Needs to be calculated separately for each retry, because it's function of time
            NSNumber *omCreationTime = [event objectForKey:@"om_creation_time"];
            if (omCreationTime != nil) {
                NSNumber* omDelta = [NSNumber numberWithLong:([OMTUtils getCurrentTimeSecs] - [omCreationTime doubleValue])];
                [event setObject:omDelta forKey:@"om_delta"];
            }
            else {
                // Backwards compatibility for old events in the queue that don't have om_creation_time.
                // Obviously value of om_delta is > 0, but know way to calculate, so just using 0.
                
                // Maybe we don't want to mess with the average delta value, so avoiding for now --Pedro
                //[event setObject:[NSNumber numberWithInt:0] forKey:@"om_delta"];
            }
                
            NSMutableString *url = [NSMutableString stringWithString:[config getURL:SMT_SERVER_TRACK]];
            [url appendString:@"?"];
                
            // om_creation_time should not be sent, however we want to have it persist in case of retry
            // therefore we will copy the event and remove it from the copy leaving it intact in the original event.
            NSMutableDictionary* eventCopy = [NSMutableDictionary dictionaryWithDictionary:event];
            [eventCopy removeObjectForKey:@"om_creation_time"];
                
            [url appendString:[OMTUtils joinDictionaryByString:eventCopy :@"&"]];
                
            responseCode = [OMTUtils getFromURL:url:&response];
            
            NSNumber* numTries = [event objectForKey:@"om_retry"];
            
            if (numTries == nil) {
                // First try, start marking retry count
                numTries = [NSNumber numberWithUnsignedInteger:1];
            } else {
                numTries = [NSNumber numberWithUnsignedInteger:[numTries unsignedIntegerValue] + 1];
            }
            
            if (responseCode >= HTTP_BAD_REQUEST) {
                [event setObject:numTries forKey:@"om_retry"];
                [persistentEventQueue save]; // Ensure retry count gets persisted
                
                [self notifyEventCallback:event WithStatus:EVENT_FAILED AndNumTries:[numTries unsignedIntegerValue]];
                
                if ([numTries unsignedIntegerValue] < maxTries) {
                    // Do retry
                    NSUInteger sleep = SLEEP_TIME * pow(2, [numTries unsignedIntegerValue]);
                    if (sleep > MAX_SLEEP) {
                        sleep = MAX_SLEEP;
                    }
                    
                    LOG(SMT_LOG_ERROR, @"Tracking event unsuccessful, will retry. Attempt: %d. Sleep %d", [numTries unsignedIntegerValue], sleep);
                    [NSThread sleepForTimeInterval:sleep];
                } else {
                    // Max retries reached, discard event
                    LOG(SMT_LOG_ERROR, @"Discarding event");
                    [self incrementDiscarded];
                    [self notifyEventCallback:event WithStatus:EVENT_DISCARDED AndNumTries:[numTries unsignedIntegerValue]];
                    [persistentEventQueue remove];
                    [persistentEventQueue save];
                }
            } else {
                [self notifyEventCallback:event WithStatus:EVENT_SUCCESS AndNumTries:[numTries unsignedIntegerValue]];
                [persistentEventQueue remove];
                [persistentEventQueue save];
            }
        }
    }
}

- (void)setEventCallback:(EventCallbackBlock) _eventCallback {
    @synchronized(self) {
        self.eventCallback = _eventCallback;
    }
}

- (void)notifyEventCallback:(NSDictionary*)event WithStatus:(OMT_EVENT_STATUS)eventStatus AndNumTries:(NSUInteger)numTries {
    if (eventCallback != nil) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            eventCallback(event, eventStatus, numTries);
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
                        [persistentEventQueue addAndSave:event.data];
                    }
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
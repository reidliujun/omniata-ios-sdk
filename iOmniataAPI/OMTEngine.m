#import "OMTEngine.h"
#import "OMTQueue.h"
#import "Logger.h"
#import "OMTUtils.h"
#import "OMTEvent.h"
#import "OMTConfig.h"
#import "SBJson.h"


@implementation OMTEngine {
    
}

- (BOOL)initialize {
    offlineDetected = NO;
    
    config = [OMTConfig instance];
    
    mEventQueue = [[OMTQueue alloc] init];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:EVENT_LOG_FILE_DIR];
    persistentEventQueue = [OMTQueue loadFromFile:[path stringByAppendingPathComponent:EVENT_LOG_FILE_NAME]];
    
    eventProcessorThread = [[NSThread alloc] initWithTarget:self selector:@selector(processEvents:) object:self];
    [eventProcessorThread start];
    
    return YES;
}

- (void)processEvents:(id)object {
    @autoreleasepool {
        lastEventUploadTime = [OMTUtils getCurrentTimeSecs];
        [self persistEvents];
        while (![eventProcessorThread isCancelled]) {
            @autoreleasepool {
                [self persistEvents];
                [self uploadEvents:flush];
                flush = NO;
            }
            [NSThread sleepForTimeInterval:EVENT_PROCESSOR_THREAD_DELAY];
        }
    }
}

- (void)uploadEvents:(BOOL)_flush {
    
    if (![self getConfig]) {
        LOG(SMT_LOG_VERBOSE, @"Upload skipped as Config is not loaded");
        return;
    }
    
    NSUInteger eventCount = [persistentEventQueue getCount];
    NSUInteger numTries = 0;
    NSUInteger retryInterval = 1;
    double currentTime = [OMTUtils getCurrentTimeSecs];
    double elapsedTime = currentTime - self->lastEventUploadTime;
    
    BOOL upload = NO;
    const NSUInteger maxBatchCount = config.maxBatchSize;
    const NSUInteger batchUploadDelay = config.batchUploadDelay;
    
    if (eventCount > 0) {
        if (_flush)  // thats a flush command
        {
            LOG(SMT_LOG_VERBOSE, @"upload triggered with FLUSH OVERRIDE");
            eventCount = eventCount >= maxBatchCount ? maxBatchCount : eventCount;
            upload = YES;
        }
        else if (elapsedTime >= batchUploadDelay) {
            LOG(SMT_LOG_VERBOSE, @"upload triggered as elapsed time %.2f is greater than bachUploadDelay %d", elapsedTime, batchUploadDelay);
            eventCount = eventCount >= maxBatchCount ? maxBatchCount : eventCount;
            upload = YES;
        }
        else if (eventCount >= maxBatchCount && !offlineDetected) {
            LOG(SMT_LOG_VERBOSE, @"upload triggered as eventCount %d is greater than maxBatchSize %d", eventCount, maxBatchCount);
            eventCount = maxBatchCount;
            upload = YES;
        }
    }
    else if (elapsedTime >= batchUploadDelay) {
        LOG(SMT_LOG_VERBOSE, @"resetting last update time as event count is 0 and time has elapsed");
        lastEventUploadTime = [OMTUtils getCurrentTimeSecs];
    }
    
    if (upload) {
        BOOL internetConnected = [OMTUtils connectedToNetwork];
        if (internetConnected) {
            offlineDetected = NO;
            retryInterval = config.retryInterval;
            OMTQueue *batchQueue = [persistentEventQueue getSubQueue:eventCount];
            
            NSMutableDictionary* mDict = [NSMutableDictionary dictionaryWithDictionary:[batchQueue remove]];
            //          [mDict addEntriesFromDictionary:config.userParams];
            
            NSMutableString *url = [NSMutableString stringWithString:[config getURL:SMT_SERVER_TRACK]];
            [url appendString:@"?"];
            [url appendString:[OMTUtils joinDictionaryByString:mDict :@"&"]];
            
            NSUInteger maxTries = config.maxRetriesForEvents;
            NSInteger responseCode = INTERNAL_SERVER_ERROR;
            NSString *response;
            
            while (responseCode > HTTP_BAD_REQUEST && numTries < maxTries) {
                responseCode = [OMTUtils getFromURL:url:&response];
                if (responseCode > HTTP_BAD_REQUEST) {
                    numTries++;
                    LOG(SMT_LOG_ERROR, @"Tracking event not successful, will retry. Attempt: %d", numTries);
                    [NSThread sleepForTimeInterval:retryInterval];
                }
            }
            
            if (responseCode >= INTERNAL_SERVER_ERROR) {
                LOG(SMT_LOG_ERROR, @"Max tries reached. Deleting events");
                
            }
            lastEventUploadTime = [OMTUtils getCurrentTimeSecs];
            [persistentEventQueue removeBlock:eventCount];
            [persistentEventQueue save];
        }
        else {
            offlineDetected = YES;
            LOG(SMT_LOG_INFO, @"Event Upload skipped: OFFLINE DEVICE");
        }
    }
    
}

- (BOOL)getConfig {
    if (!eventConfigLoaded) {
        eventConfigLoaded = [config getEventConfig];
    }
    return eventConfigLoaded;
}



- (void)persistEvents {
    NSUInteger eventCount = [mEventQueue getCount];
    BOOL hasEvents = (eventCount > 0);
    for (NSInteger i = 0; i < eventCount; i++) {
        OMTEvent *event = [mEventQueue remove];
        [persistentEventQueue add:event.data];
    }
    if (hasEvents) {
        [persistentEventQueue save];
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


- (void)flushEventsQueue {
    //set the flush flag.....
    flush = TRUE;
    LOG(SMT_LOG_INFO, @"FLUSH Enabled");
}

- (void)dealloc {
    config = nil;
    mEventQueue = nil;
    persistentEventQueue = nil;
    eventProcessorThread = nil;
}


@end
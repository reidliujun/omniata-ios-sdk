#import "OMTConfig.h"
#import "OMTUtils.h"
#import "SBJson.h"

///////////////////////////SINGLETON/////////////////////
@interface OMTConfig ()
- (id)initSingleton;

- (BOOL)initEventConfig:(NSString *)string;
- (void)setUrls;
@end

@implementation OMTConfig
- (id)initSingleton {
    if ((self = [super init])) {
        // Initialization code here.
    }

    return self;
}

+ (OMTConfig *)instance {
    // Persistent instance.
    static OMTConfig *_default = nil;

    // Small optimization to avoid wasting time after the
    // singleton being initialized.
    if (_default != nil) {
        return _default;
    }

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    // Allocates once with Grand Central Dispatch (GCD) routine.
    // It's thread safe.
    static dispatch_once_t safer;
    dispatch_once(&safer, ^(void) {
        _default = [[OMTConfig alloc] initSingleton];
    });
#else
    // Allocates once using the old approach, it's slower.
    // It's thread safe.
    @synchronized([MySingleton class])
    {
        // The synchronized instruction will make sure,
        // that only one thread will access this point at a time.
        if (_default == nil)
        {
            _default = [[MySingleton alloc] initSingleton];
        }
    }
#endif
    return _default;
}

/////////////////////////////////////////////
@synthesize maxBatchSize;
@synthesize batchUploadDelay;
@synthesize maxRetriesForEvents;
@synthesize retryInterval;
@synthesize userParams;
@synthesize maxRetriesForChannelMessages;

static SMT_LOG logType = SMT_LOG_NONE;
static NSString *rooturl = nil;
static NSString *trackUrl = nil;
static NSString *configUrl = nil;
static NSString *channelUrl = nil;
static BOOL debug = false;


- (void)setLogType:(SMT_LOG)logVal {
    logType = logVal;
}

- (SMT_LOG)getLogType {
    return logType;
}

- (void)initialize:(NSMutableDictionary *)param :(BOOL)dbg{
    debug = dbg;
    [self setUrls];
    self->userParams = param;
}

- (void)setUrls {    
    if (debug) {
        LOG(SMT_LOG_INFO, @"DEBUG TRUE");
        rooturl = TEST_URL;
    } else {
        LOG(SMT_LOG_INFO, @"DEBUG FALSE");
        rooturl = ROOT_URL;
    }
   trackUrl = [NSString stringWithFormat:@"%@%@", rooturl, EVENTS_TRACK_SUB_URL];
   configUrl = [NSString stringWithFormat:@"%@%@", rooturl, CONFIG_SUB_URL];
   channelUrl = [NSString stringWithFormat:@"%@%@",rooturl, CHANNEL_MSGS_SUB_URL];
}

- (NSString *)getURL:(SMT_SERVERS)serverId {
    switch (serverId) {
        case SMT_SERVER_CONFIG:
            return configUrl;
        case SMT_SERVER_TRACK:
            return trackUrl;
        case SMT_SERVER_CHANNEL:
            return channelUrl;
        default:
            LOG(SMT_LOG_ERROR, @"Cant find url for id %d", serverId);
            break;
    }
    return nil;
}

- (BOOL)getEventConfig {
    BOOL updated = NO;
    NSString *string;
    
    //[OMTUtils getFromURL:[self getURL:SMT_SERVER_CONFIG] :&string];
    if (false && [string rangeOfString:ERROR].location == NSNotFound) //if string has no value that contains "ERROR";//todo:Jijo: bad error check. change it later to more readable.
    {
        LOG(SMT_LOG_INFO, @"configuration received from server");
    }
    else {
        LOG(SMT_LOG_WARN, @"configuration not received from server. Loading defaults");
        
        string = @"{ \n"
        "    \"max_track_retries\":3, \n"
        "    \"max_channel_retries\":3, \n"
        "    \"max_batch_size\":1, \n"
        "    \"max_batch_delay\":0, \n"
        "    \"retry_delay\":4 \n"
        "} ";
    }
    updated = [self initEventConfig:string];
    return updated;
}


- (BOOL)initEventConfig:(NSString *)string {
    BOOL isSuccess = NO;
    NSDictionary *dictionary = [string JSONValue];
    if (!dictionary) {
        LOG(SMT_LOG_ERROR, @"Invalid JSON data for Event Config");
    }
    else {
        NSNumber *val = [dictionary objectForKey:CONFIG_JSON_MAX_TRACK_RETRIES];
        if (!val) {
            LOG(SMT_LOG_ERROR, @"Value not found for %@ in config", CONFIG_JSON_MAX_TRACK_RETRIES);
            return isSuccess;
        }
        maxRetriesForEvents = [val unsignedIntValue];

        val = [dictionary objectForKey:CONFIG_JSON_MAX_CHANNEL_RETRIES];
        if (!val) {
            LOG(SMT_LOG_ERROR, @"Value not found for %@ in config", CONFIG_JSON_MAX_CHANNEL_RETRIES);
            return isSuccess;
        }
        maxRetriesForChannelMessages = [val unsignedIntValue];

        val = [dictionary objectForKey:CONFIG_JSON_MAX_BATCH_SIZE];
        if (!val) {
            LOG(SMT_LOG_ERROR, @"Value not found for %@ in config", CONFIG_JSON_MAX_BATCH_SIZE);
            return isSuccess;
        }
        maxBatchSize = [val unsignedIntValue];

        val = [dictionary objectForKey:CONFIG_JSON_BATCH_DELAY];
        if (!val) {
            LOG(SMT_LOG_ERROR, @"Value not found for %@ in config", CONFIG_JSON_BATCH_DELAY);
            return isSuccess;
        }
        batchUploadDelay = [val unsignedIntValue];

        val = [dictionary objectForKey:CONFIG_JSON_MIN_RETRY_DELAY];
        if (!val) {
            LOG(SMT_LOG_ERROR, @"Value not found for %@ in config", CONFIG_JSON_MIN_RETRY_DELAY);
            return isSuccess;
        }
        retryInterval = [val unsignedIntValue];
        isSuccess = YES;
        LOG(SMT_LOG_INFO, @"Event CONFIG loaded successfully");
        LOG(SMT_LOG_VERBOSE, @"maxRetriesForEvents:%d", maxRetriesForEvents);
        LOG(SMT_LOG_VERBOSE, @"maxRetriesForChannel:%d", maxRetriesForChannelMessages);
        LOG(SMT_LOG_VERBOSE, @"maxBatchSize:%d", maxBatchSize);
        LOG(SMT_LOG_VERBOSE, @"batchUploadDelay:%d", batchUploadDelay);
        LOG(SMT_LOG_VERBOSE, @"retryInterval:%d", retryInterval);
    }
    return isSuccess;
}

- (void)dealloc {
    userParams = nil;

}

@end
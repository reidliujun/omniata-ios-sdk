#import "OMTConfig.h"
#import "OMTUtils.h"
#import "OmSBJson.h"
#import "Reachability.h"

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
@synthesize reachability;

static SMT_LOG logType = SMT_LOG_NONE;
static NSString *rooturl = nil;
static NSString *trackUrl = nil;
static NSString *configUrl = nil;
static NSString *channelUrl = nil;
static NSString *org = nil;


- (void)setLogType:(SMT_LOG)logVal {
    logType = logVal;
}

- (SMT_LOG)getLogType {
    return logType;
}

// Initilization for multiple URL of different services
- (void)initialize:(NSMutableDictionary *)param :(NSString *)orgname{
    org = orgname;
    
    [self setUrls];
   
    // reachability may have already been set, if so, don't attempt to assign default reachability
    if (reachability == nil) {
        [self setReachability:^{
            return [OMTUtils defaultReachabilityCheck];
        }];
    }
    
    self->userParams = param;
}

- (void)setUrls {
        LOG(SMT_LOG_INFO, @"CUSTOMIZED URL");
            //https does not work now, will support soon.
        trackUrl = [NSString stringWithFormat:@"https://%@.%@.%@%@", org, @"analyzer",BASE_URL,EVENTS_TRACK_SUB_URL];
//       NSLog(@"trackurl: %@", trackUrl);

        rooturl = ROOT_URL;
        configUrl = [NSString stringWithFormat:@"%@%@", rooturl, CONFIG_SUB_URL];
        channelUrl = [NSString stringWithFormat:@"https://%@.%@.%@%@", org, @"engager",BASE_URL,CHANNEL_MSGS_SUB_URL];
//        NSLog(@"channelurl: %@", channelUrl);
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

#ifdef DEVELOPMENT
    string = @"{ \n"
    "    \"max_track_retries\":50, \n"
    "    \"max_channel_retries\":3, \n"
    "    \"max_batch_size\":1, \n"
    "    \"max_batch_delay\":0, \n"
    "    \"retry_delay\":4 \n"
    "} ";
#else
    string = @"{ \n"
    "    \"max_track_retries\":50, \n"
    "    \"max_channel_retries\":3, \n"
    "    \"max_batch_size\":1, \n"
    "    \"max_batch_delay\":0, \n"
    "    \"retry_delay\":4 \n"
    "} ";
#endif
    
    updated = [self initEventConfig:string];
    return updated;
}


- (BOOL)initEventConfig:(NSString *)string {
    BOOL isSuccess = NO;
    NSDictionary *dictionary = [string OmJSONValue];
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

- (void)setReachability:(BOOL (^)(void))_reachability {
    reachability = _reachability;
}

- (void)dealloc {
    userParams = nil;

}

@end
#import <AdSupport/AdSupport.h>
#import <CoreLocation/CoreLocation.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import "iOmniataAPI.h"
#import "OMTConfig.h"
#import "OMTEngine.h"
#import "OMTUtils.h"
#import "OMTChannelEngine.h"

@interface iOmniataAPI()

+(NSDictionary*)getDeviceParams;
+(NSString*)getHardware;

@end

@implementation iOmniataAPI
static BOOL initialized = false;
static OMTEngine * trackerEngine;
static OMTChannelEngine *channelEngine;

+ (void)initializeWithApiKey:(NSString *)api_key UserId:(NSString *)user_id AndDebug:(BOOL)debug {
    LOG(SMT_LOG_INFO, @"Initializing library");
    OMTConfig * config = [OMTConfig instance];
    if (!initialized) {
        NSException *exception;
        NSString * errorString;
        if(api_key == nil || [api_key length] <= 0)
        {
            errorString = @"api_key cannot be nil or empty";
        }
        if (user_id == nil || [user_id length] <= 0)
        {
            errorString = @"user_id cannot be nil or empty";
        }
        
        if(errorString != nil)
        {
            exception = [NSException exceptionWithName:@"InvalidInitializationException" reason:errorString userInfo:nil];
            @throw exception;
        }
        NSMutableDictionary * userParams = [NSMutableDictionary dictionaryWithObjectsAndKeys: api_key, @"api_key", user_id, @"uid", nil];
        
        [config initialize:userParams:debug];
        trackerEngine = [[OMTEngine alloc] init];
        channelEngine = [[OMTChannelEngine alloc] init];
        BOOL result = [trackerEngine initialize];
        if(!result)
        {
            exception = [NSException exceptionWithName:@"InvalidInitializationException" reason:@"Error Initializing TrackerEngine" userInfo:nil];
            @throw exception;
        }
        initialized = YES;
        LOG(SMT_LOG_INFO, @"Successfully initialized library");
    }
    else {
        LOG(SMT_LOG_WARN, @"Duplicate Initialization call");
    }
}

+ (void)setLogLevel:(SMT_LOG)logLevel {
    [[OMTConfig instance] setLogType:logLevel];
}

+ (void)setApiKey:(NSString *)api_key {
    [[OMTConfig instance].userParams setObject:api_key forKey:@"api_key"];
}

+ (void)setUserId:(NSString *)user_id {
    [[OMTConfig instance].userParams setObject:user_id forKey:@"uid"];
}

+ (BOOL)trackEvent:(NSString*)type :(NSDictionary *)param {
    LOG(SMT_LOG_INFO, @"Calling trackEvent");
    
    if (!initialized)
    {
        @throw [NSException exceptionWithName:@"PrematureTrackingException" reason:@"library is not yet initialized" userInfo:nil];
    }
    if (type == nil)
    {
        @throw [NSException exceptionWithName:@"InvalidParameterException" reason:@"type cannot be nil" userInfo:nil];
    }
    OMTConfig* config = [OMTConfig instance];
    
    NSMutableDictionary* mDict = [NSMutableDictionary dictionaryWithDictionary:param];
    [mDict setObject:type forKey:@"om_event_type"];
    [mDict addEntriesFromDictionary:config.userParams];
    
    LOG(SMT_LOG_INFO, @"LE EVENT: %@", mDict);
    
    BOOL result =  [trackerEngine addEvent:mDict];
    if (result)
    {
        LOG(SMT_LOG_INFO, @"event successfully added for tracking");
    }
    return  result;
}

+ (BOOL)trackPurchaseEvent:(double)total currency_code:(NSString *)currency_code {
    return [iOmniataAPI trackPurchaseEvent:total currency_code:currency_code additional_params:nil];
}

+ (BOOL)trackPurchaseEvent:(double)total currency_code:(NSString *)currency_code additional_params:(NSDictionary *)additional_params {
    NSMutableDictionary* params;
    
    if (currency_code == nil) {
        currency_code = @"USD";
    }
    
    params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithDouble:total], @"total",
              currency_code, @"currency_code", nil];
    
    if (additional_params != nil) {
        [params addEntriesFromDictionary:additional_params];
    }
    
    return [iOmniataAPI trackEvent:@"om_revenue" :params];
}

+ (BOOL)trackLoadEvent {
    // Default Params    
    return [iOmniataAPI trackEvent:@"om_load" : [iOmniataAPI getDeviceParams]];
}

+ (BOOL)trackLoadEventWithParameters:(NSDictionary*)parameters {
    NSMutableDictionary* mdict = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [mdict addEntriesFromDictionary:[iOmniataAPI getDeviceParams]];
    return [iOmniataAPI trackEvent:@"om_load" : parameters];
}

+ (NSDictionary*) getDeviceParams {
    NSString* idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSString* systemName = [[UIDevice currentDevice] systemName];
    NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString* model = [[UIDevice currentDevice] model];
    NSString* machine = [iOmniataAPI getHardware];
    NSString* platform = @"iOS";
    NSString* locale = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            idfa, @"om_ios_idfa",
                            systemName, @"om_ios_sysname",
                            systemVersion, @"om_ios_sysver",
                            model, @"om_ios_model",
                            machine, @"om_ios_hardware",
                            platform, @"om_platform",
                            locale, @"om_locale",
                            nil];
    
    return params;
}

+ (NSString*) getHardware {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (void)loadMessagesForChannel:(NSUInteger)channelID completionHandler:(void (^)(OMT_CHANNEL_STATUS))completionBlock {
    if (!initialized)
    {
        @throw [NSException exceptionWithName:@"PrematureLoadCallException" reason:@"Library is not yet initialized" userInfo:nil];
    }
    [channelEngine loadMessagesForChannel:channelID completionHandler:completionBlock];
}

+ (NSArray *)getChannelMessages {
    if (!initialized)
    {
        @throw [NSException exceptionWithName:@"PrematureLoadCallException" reason:@"Library is not yet initialized" userInfo:nil];
    }
    return channelEngine.messages;
}

+ (void)setReachability:(BOOL(^)(void))reachability {
    [[OMTConfig instance] setReachability:reachability];
}


+ (NSString *)getAgentVersion {
    return iOMT_TRACKER_VERSION;
}

@end
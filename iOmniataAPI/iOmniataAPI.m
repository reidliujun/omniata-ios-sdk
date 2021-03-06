#import <CoreLocation/CoreLocation.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import "iOmniataAPI.h"
#import "OMTConfig.h"
#import "OMTEngine.h"
#import "OMTUtils.h"
#import "OMTChannelEngine.h"
#import "Logger.h"

@interface iOmniataAPI()

+(NSDictionary*)createAutomaticParameters;
+(NSString*)getHardware;

@end

@implementation iOmniataAPI
static BOOL initialized = false;
static BOOL automaticParametersEnabled = true;
static OMTEngine * trackerEngine;
static OMTChannelEngine *channelEngine;

+ (void)initializeWithApiKey:(NSString *)api_key UserId:(NSString *)user_id OrgName:(NSString *)org {
    [self initializeWithApiKey:api_key UserId:user_id OrgName:org EventCallbackBlock:nil];
}

+ (void)initializeWithApiKey:(NSString *)api_key UserId:(NSString *)user_id OrgName:(NSString *)org EventCallbackBlock:(EventCallbackBlock) eventCallback {
    NSMutableDictionary *userParams;
    
    LOG(SMT_LOG_INFO, @"Initializing library");
    
    @synchronized(self) {
        if (!initialized) {
            [self assertApiKeyValid:api_key];
            [self assertUserIdValid:user_id];
            
            // set TEST_URL inside of OMTConstants.
            //TEST_URL = [NSString stringWithFormat: @"%@.%@.%@", org,service,BASE_URL];
            
            userParams = [[NSMutableDictionary alloc] init];
            [userParams setObject:api_key forKey:@"api_key"];
            [userParams setObject:user_id forKey:@"uid"];
            
            [[OMTConfig instance] initialize:userParams:org];
            trackerEngine = [[OMTEngine alloc] init];
            channelEngine = [[OMTChannelEngine alloc] init];
            BOOL result = [trackerEngine initialize:eventCallback];
            if(!result) {
                @throw[NSException exceptionWithName:@"InvalidInitializationException" reason:@"Error Initializing TrackerEngine" userInfo:nil];
            }
            initialized = YES;
            LOG(SMT_LOG_INFO, @"Successfully initialized library");
        }
        else {
            LOG(SMT_LOG_WARN, @"Duplicate Initialization call");
        }
    }
}

+ (void)setLogLevel:(SMT_LOG)logLevel {
    [[OMTConfig instance] setLogType:logLevel];
}

+ (void)setApiKey:(NSString *)api_key {
    @synchronized(self) {
        [self assertInitialized];
        [[OMTConfig instance].userParams setObject:api_key forKey:@"api_key"];
    }
}

+ (void)setUserId:(NSString *)user_id {
    @synchronized(self) {
        [self assertInitialized];
        [[OMTConfig instance].userParams setObject:user_id forKey:@"uid"];
    }
}

+ (void)setEventCallback:(EventCallbackBlock) eventCallback {
    @synchronized(self) {
        [self assertInitialized];
        [trackerEngine setEventCallback:eventCallback];
    }
}

+ (void)assertInitialized {
    if (!initialized) {
        @throw [NSException exceptionWithName:@"PrematureTrackingException" reason:@"library is not yet initialized" userInfo:nil];
    }
}

+ (void)assertApiKeyValid:(NSString*)apiKey {
    if (apiKey == nil || [apiKey length] == 0) {
        @throw [NSException exceptionWithName:@"InvalidArgumentException" reason:@"api_key cannot be nil or empty" userInfo:nil];
    }
}

+ (void)assertUserIdValid:(NSString*)userId {
    if (userId == nil || [userId length] == 0) {
        @throw [NSException exceptionWithName:@"InvalidArgumentException" reason:@"user_id cannot be nil or empty" userInfo:nil];
    }
}

+ (void)assertValidEventType:(NSString*)type {
    if (type == nil || [type length] == 0) {
        @throw [NSException exceptionWithName:@"InvalidArgumentException" reason:@"event type cannot be nil or empty" userInfo:nil];
    }
}

+ (BOOL)trackEvent:(NSString*)type :(NSDictionary *)parameters {
    NSMutableDictionary* eventData = [[NSMutableDictionary alloc] init];
    NSNumber*            createdAt = [NSNumber numberWithDouble:[OMTUtils getCurrentTimeSecs]];
    
    LOG(SMT_LOG_INFO, @"Calling trackEvent");
    
    @synchronized(self) {
        [self assertInitialized];
        [self assertValidEventType:type];

        OMTConfig* config = [OMTConfig instance];
        
        [eventData setObject:type forKey:@"om_event_type"];
        [eventData setObject:createdAt forKey:@"om_creation_time"];
        [eventData addEntriesFromDictionary:config.userParams];
        
        if (parameters != nil) {
            [eventData addEntriesFromDictionary:parameters];
        }
        
        LOG(SMT_LOG_INFO, @"tracking event: %@", eventData);
        
        BOOL result = [trackerEngine addEvent:eventData];
        
        if (result) {
            LOG(SMT_LOG_INFO, @"event successfully added for tracking");
        }
        
        return result;
    }
}

+ (BOOL)trackPurchaseEvent:(double)total currency_code:(NSString *)currency_code {
    return [iOmniataAPI trackPurchaseEvent:total currency_code:currency_code additional_params:nil];
}

+ (BOOL)trackPurchaseEvent:(double)total currency_code:(NSString *)currency_code additional_params:(NSDictionary *)additional_params {
    NSMutableDictionary* parameters = [[NSMutableDictionary alloc] init];
    
    if (currency_code == nil) {
        currency_code = @"USD";
    }
    
    [parameters setObject:[NSNumber numberWithDouble:total] forKey:@"total"];
    [parameters setObject:currency_code forKey:@"currency_code"];
    
    if (additional_params != nil) {
        [parameters addEntriesFromDictionary:additional_params];
    }
    
    return [iOmniataAPI trackEvent:@"om_revenue" :parameters];
}

+ (BOOL)trackLoadEvent {
    return [iOmniataAPI trackLoadEventWithParameters:nil];
}

+ (BOOL)trackLoadEventWithParameters:(NSDictionary*)parameters {
    NSMutableDictionary* mdict = [[NSMutableDictionary alloc] init];
    
    if (parameters != nil) {
        [mdict addEntriesFromDictionary:parameters];
    }
    if (automaticParametersEnabled) {
        [mdict addEntriesFromDictionary:[iOmniataAPI createAutomaticParameters]];
    }
    return [iOmniataAPI trackEvent:@"om_load" : mdict];
}

+ (NSDictionary*) createAutomaticParameters {
    NSString* omDevice = [iOmniataAPI getHardware];
    NSString* omPlatform = @"ios";
    NSString* omOsVersion = [[UIDevice currentDevice] systemVersion];
    NSString* omSdkVersion = [iOmniataAPI getAgentVersion];
    NSNumber* omDiscarded = [NSNumber numberWithInteger:[trackerEngine getDiscarded]];

    NSString* locale = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    NSString* model = [[UIDevice currentDevice] model];
    NSString* systemName = [[UIDevice currentDevice] systemName];
    
    NSString *bundleShortVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersionKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    NSString *bundleIdentifierKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];

    return [NSDictionary dictionaryWithObjectsAndKeys:
            // Standard automatic parameters
            omDevice, @"om_device",
            omPlatform, @"om_platform",
            omOsVersion, @"om_os_version",
            omSdkVersion, @"om_sdk_version",
            omDiscarded, OM_DISCARDED,
            // ios-specific standard parameters
            bundleShortVersionString, @"om_ios_bundle_short_version_string",
            bundleVersionKey, @"om_ios_bundle_version",
            bundleIdentifierKey, @"om_ios_bundle_identifier",

            // Backwards compatibility for older version of the SDK
            omDevice, @"om_ios_hardware",
            locale, @"om_locale",
            model, @"om_ios_model",
            systemName, @"om_ios_sysname",
            omOsVersion, @"om_ios_sysver",

            nil];
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
    return SDK_VERSION;
}

+ (void)enablePushNotifications:(NSData*)deviceToken {
    NSMutableDictionary* params;
    
    @synchronized(self) {
        [self assertInitialized];
        params = [[NSMutableDictionary alloc] init];
        [params setObject:[deviceToken description] forKey:@"om_device_token"];
        [iOmniataAPI trackEvent:@"om_apns_enable" : params];
    }
}

+ (void)disablePushNotifications {
    @synchronized(self) {
        [self assertInitialized];
        [iOmniataAPI trackEvent:@"om_apns_disable" : nil];
    }
}

@end
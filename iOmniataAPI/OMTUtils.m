#import <SystemConfiguration/SystemConfiguration.h>
#include <netinet/in.h>
#import "OMTUtils.h"
#import "Logger.h"
#import "Reachability.h"
#import "OMTConfig.h"

@interface OMTUtils ()
//private methods
+ (NSInteger)connect:(NSString *)urlStr data:(NSString *)str responseStr:(NSString **)responseStr responseNeeded:(BOOL)responseNeeded;
@end

@implementation OMTUtils

+ (double)getCurrentTimeSecs {
    return [[NSDate date] timeIntervalSince1970];
}

+ (NSInteger)postToURL:(NSString *)urlStr :(NSString *)jsonStr :(NSString **)responseStr responseNeeded:(BOOL)responseNeeded {
    LOG(SMT_LOG_VERBOSE, @"SENDING_DATA");
    LOG(SMT_LOG_VERBOSE, @"URL : %@", urlStr);
    if (jsonStr == nil) {
        LOG(SMT_LOG_VERBOSE, @"post Data : NIL");
    }
    else {
        LOG(SMT_LOG_VERBOSE, @"post Data :%@", jsonStr);
    }
    return [self connect:urlStr data:jsonStr responseStr:responseStr responseNeeded:responseNeeded];
}

+ (NSInteger)getFromURL:(NSString *)urlStr :(NSString **)responseStr {
    LOG(SMT_LOG_VERBOSE, @"FETCHING_DATA");
    LOG(SMT_LOG_VERBOSE, @"URL : %@", urlStr);
    return [self connect:urlStr data:nil responseStr:responseStr responseNeeded:FALSE];
}

+ (NSInteger)connect:(NSString *)urlStr data:(NSString *)str responseStr:(NSString **)responseStr responseNeeded:(BOOL)responseNeeded {
    NSInteger responseCode = INTERNAL_SERVER_ERROR;
    *responseStr = @"ERROR::Could Not Establish Connection";
    @try {
        NSURL *url = [NSURL URLWithString:urlStr];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];

        NSURLResponse *response;
        NSError *error;
        NSData *conData;
        if (str != nil) {
            NSData *postData = [str dataUsingEncoding:NSUTF8StringEncoding];
            [urlRequest setHTTPMethod:@"POST"];
            [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
            [urlRequest setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-length"];
            [urlRequest setHTTPBody:postData];
        }

        conData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        if (conData == nil) {
            LOG(SMT_LOG_ERROR, @"ERROR:Connection FAILED!!!");
        }
        else {
            if (response != nil) {
                responseCode = [(NSHTTPURLResponse *) response statusCode];
                LOG(SMT_LOG_INFO, @"Response Code %d", responseCode);
                if (responseCode == HTTP_OK) {
                    *responseStr = [[NSString alloc] initWithData:conData encoding:NSUTF8StringEncoding];
                    if (*responseStr != nil && [*responseStr length] > 0) {
                        LOG(SMT_LOG_VERBOSE, @"HTTP response is %@", *responseStr);
                    }
                    else {
                        if(responseNeeded)
                        {
                            responseCode = INTERNAL_SERVER_ERROR;
                            *responseStr = @"ERROR: No Data from Server";
                            LOG(SMT_LOG_ERROR, @"Error: No Data from Server");
                        }
                        else{
                            *responseStr = @"No Data from Server";
                            LOG(SMT_LOG_INFO, @"Not bothered for no response from server as responseNeeded param is NO");
                        }
                        
                    }
                }
                else {
                    LOG(SMT_LOG_ERROR, @"ERROR:URL Returned error");
                }
            }
            else {
                LOG(SMT_LOG_ERROR, @"ERROR:Response object is null");
            }
        }
    }
    @catch (NSException *exception1) {
        *responseStr = @"Error: Exception while connecting";
        LOG(SMT_LOG_ERROR, @"Exception occurred while connecting: %@, %@", exception1, [exception1 userInfo]);
    }
    return responseCode;
}

+ (BOOL)connectedToNetwork {
    return [[OMTConfig instance] reachability]();
}

+ (BOOL)defaultReachabilityCheck {
    Reachability * reach = [Reachability reachabilityWithHostName:@"api.omniata.com"];
    NetworkStatus networkStatus = [reach currentReachabilityStatus];
    return (BOOL) !(networkStatus == NotReachable);
}

+ (BOOL)isValidCurrencyCode:(NSString *)currencyCode
{
    NSArray * codesArray = [NSLocale ISOCurrencyCodes];
    return [codesArray containsObject:currencyCode];
}

+ (NSString *)joinDictionaryByString:(NSDictionary *)dictionary :(NSString *)delimiter {
    NSMutableArray* parametersArray = [[NSMutableArray alloc] init];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* encodedKey = [OMTUtils urlEncodeString: [NSString stringWithFormat:@"%@", key]];
        NSString* encodedVal = [OMTUtils urlEncodeString: [NSString stringWithFormat:@"%@", obj]];

        [parametersArray addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedVal]];
    }];
    return [parametersArray componentsJoinedByString:@"&"];
}

+ (NSString *)joinArrayByString:(NSArray *)array :(NSString *)delimiter {
    return [array componentsJoinedByString:@"&"];
}

+ (NSString *) urlEncodeString:(NSString*)string {
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[string UTF8String];
    int sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

@end
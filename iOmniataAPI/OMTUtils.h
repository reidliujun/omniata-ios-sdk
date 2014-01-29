#import <Foundation/Foundation.h>


@interface OMTUtils : NSObject
+ (double)getCurrentTimeSecs;

+ (NSInteger)postToURL:(NSString *)urlStr :(NSString *)jsonStr :(NSString **)responseStr responseNeeded:(BOOL)responseNeeded;

+ (NSInteger)getFromURL:(NSString *)urlStr :(NSString **)responseStr;

+ (BOOL)connectedToNetwork;

+ (BOOL)isValidCurrencyCode:(NSString *)currencyCode;

+ (NSString *)joinDictionaryByString:(NSDictionary *)dictionary :(NSString *)delimiter;

+ (NSString *)joinArrayByString:(NSArray *)array :(NSString *)delimiter;


@end
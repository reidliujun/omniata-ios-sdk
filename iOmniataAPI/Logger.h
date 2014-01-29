#import <Foundation/Foundation.h>
#import "iOmniataAPI.h"



@interface Logger : NSObject

+(void)log:(SMT_LOG)log_Type :(NSString *) str :(NSString *)format, ...;
@end

#define LOG(log_type, format, ...)   \
[Logger log: log_type: [NSString stringWithFormat:@"%s:%d",__PRETTY_FUNCTION__,__LINE__ ]: format, ## __VA_ARGS__ ];

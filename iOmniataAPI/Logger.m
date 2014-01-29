#import "Logger.h"
#import "OMTConfig.h"




@implementation Logger

static unsigned int userLogType = 0;

+ (void)log:(SMT_LOG)log_Type :(NSString *)str :(NSString *)format, ... {
    if (userLogType == 0)
    {
        userLogType = [[OMTConfig instance] getLogType];
    }
    if (log_Type > userLogType) return;
    NSString *logTypeMsg;
    switch (log_Type) {
        case SMT_LOG_INFO:
            logTypeMsg = @"INFO";
            break;
        case SMT_LOG_WARN:
            logTypeMsg = @"WARN";
            break;
        case SMT_LOG_ERROR:
            logTypeMsg = @"ERROR";
            break;
        case SMT_LOG_VERBOSE:
            logTypeMsg = @"VERBOSE";
            break;
        default:
            NSLog(@"iOmniataAPI: ERROR: unknown error at %@", str);
            return;
    }

    va_list args;
    va_start(args, format);
    NSString *tempStr = [[NSString alloc] initWithFormat:format arguments:args];
    NSLog(@"%@ : %@ : %@:%@ ", iOMNIATA, logTypeMsg, str, tempStr);
    va_end(args);
}
@end
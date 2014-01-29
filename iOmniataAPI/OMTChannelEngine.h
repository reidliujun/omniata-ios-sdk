#import <Foundation/Foundation.h>


@interface OMTChannelEngine : NSObject
{
@private
    NSArray *messages;
    BOOL loadingMessages;
    NSUInteger maxRetries;
    NSString *channelURL;
}

//these two are getters used within this class. I am using the system property of atomicity while accessing this variable.
//as these two variables will be modified by other threads.
@property (readonly) NSArray * messages;
@property (readonly) BOOL loadingMessages;

-(void)loadMessagesForChannel:(NSUInteger)channelID completionHandler:(void (^)(OMT_CHANNEL_STATUS))completionBlock;
@end
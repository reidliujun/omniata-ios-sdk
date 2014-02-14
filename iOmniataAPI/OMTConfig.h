#import <Foundation/Foundation.h>

#include "iOmniataAPI.h"
@interface OMTConfig : NSObject
{
    @private
    NSUInteger    maxBatchSize;
    NSUInteger    batchUploadDelay;
    NSUInteger    maxRetriesForEvents;
    NSUInteger    maxRetriesForChannelMessages;
    NSUInteger    retryInterval;
    NSMutableDictionary* userParams;
}
@property(readonly, assign) NSUInteger maxBatchSize;
@property(readonly, assign) NSUInteger batchUploadDelay;
@property(readonly, assign) NSUInteger maxRetriesForEvents;
@property(readonly, assign) NSUInteger maxRetriesForChannelMessages;
@property(readonly, assign) NSUInteger retryInterval;
@property(readonly, copy)   NSMutableDictionary *userParams;
@property(readonly, assign) BOOL(^reachability)(void);


+(OMTConfig *)instance;
-(void) setLogType:(SMT_LOG) logVal;
-(SMT_LOG) getLogType;

- (void)initialize:(NSMutableDictionary *)param :(BOOL)debug;
-(NSString *)getURL:(SMT_SERVERS)serverId;
- (void)setReachability:(BOOL (^)(void))reachability;

- (BOOL)getEventConfig;
@end


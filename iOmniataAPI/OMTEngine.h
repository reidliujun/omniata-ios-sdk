#import <Foundation/Foundation.h>
#import "iOmniataAPI.h"
@class OMTQueue;
@class OMTConfig;


@interface OMTEngine : NSObject
{
    @private

    OMTQueue *mEventQueue;
    OMTQueue *persistentEventQueue;
    NSThread *eventPersistThread;
    NSThread *eventProcessorThread;
    BOOL eventConfigLoaded;
    EventCallbackBlock eventCallback;

    OMTConfig * config;
}
- (BOOL)initialize:(EventCallbackBlock) eventCallback;
- (BOOL)addEvent:(NSDictionary *)param;
- (void)setEventCallback:(EventCallbackBlock) eventCallback;

- (BOOL)getConfig;
- (NSInteger)getDiscarded;

@end
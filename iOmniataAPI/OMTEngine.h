#import <Foundation/Foundation.h>

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
    double lastEventUploadTime;
    BOOL offlineDetected;

    OMTConfig * config;
}
- (BOOL)initialize;
- (BOOL)addEvent:(NSDictionary *)param;


- (BOOL)getConfig;
- (NSInteger)getDiscarded;

@end
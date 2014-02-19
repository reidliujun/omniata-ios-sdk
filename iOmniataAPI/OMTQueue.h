#import <Foundation/Foundation.h>

@interface OMTQueue : NSObject {
    NSRecursiveLock *queLock;
    NSMutableArray *queue;
    NSString *fileName;
}

- (id)init;

- (void)add :(id)object;

- (id)initWithArray:(NSArray *)array;

- (id)remove;

-(void)removeBlock:(NSUInteger)count;

-(OMTQueue *) getSubQueue:(NSUInteger) count;

- (BOOL)isEmpty;

- (NSUInteger)getCount;

+ (OMTQueue *)loadFromFile:(NSString *)fileName;

- (BOOL)save;

@end
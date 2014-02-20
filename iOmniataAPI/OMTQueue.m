#import "OMTQueue.h"
#import "Logger.h"

@interface OMTQueue ()

- (BOOL)writeToFile;

@end

@implementation OMTQueue {

}

- (id)init {
    if (self = [super init]) {
        queue = [[NSMutableArray alloc] init];
        queLock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (void)add:(id)object {
    [queLock lock];

    [queue insertObject:object atIndex:[queue count]];
    [queLock unlock];
}

- (id)initWithArray:(NSArray *)array {
    if (self = [super init])
    {
        queue = [[NSMutableArray alloc] initWithArray:array];
        queLock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (id)remove {
    id object = nil;
    [queLock lock];
    NSUInteger count = [queue count];
    if (count > 0) {
        object = [queue objectAtIndex:0]; //todo: JIJO not doing retain, assuming ARC takes care.
        [queue removeObjectAtIndex:0];
    }
    [queLock unlock];
    return object;
}

- (void)removeBlock:(NSUInteger)count {
    NSRange range;
    range.location = 0;
    range.length = count;
    [queLock lock];
    if (count <= [queue count]) {
        [queue removeObjectsInRange:range];
    }
    [queLock unlock];
}

- (OMTQueue *)getSubQueue:(NSUInteger)count {
    NSArray * array;

    NSRange range;
    range.location = 0;
    range.length = count;

    [queLock lock];
    array = [queue subarrayWithRange:range];
    [queLock unlock];

    return [[OMTQueue alloc] initWithArray:array];
}

- (BOOL)isEmpty {
  return [self getCount] == 0;
}

- (NSUInteger)getCount {
    NSUInteger count = 0;
    [queLock lock];
    count = [queue count];
    [queLock unlock];
    return count;
}

+ (OMTQueue *)loadFromFile:(NSString *)fileName {
    OMTQueue *smtQueue = [NSKeyedUnarchiver unarchiveObjectWithFile:fileName];

    if (smtQueue == nil) {
        smtQueue = [[OMTQueue alloc] init];
    }
    smtQueue->fileName = fileName;
    return smtQueue;
}

- (BOOL)writeToFile {
    BOOL success = NO;
    if (fileName) {
        [queLock lock];
        success = [NSKeyedArchiver archiveRootObject:self toFile:fileName];
        [queLock unlock];
    }
    else {
        LOG(SMT_LOG_WARN, @"Cannot save queue to file as these is not file name");
    }
    return success;
}

- (id)peek {
    id object = nil;
    [queLock lock];
    if ([queue count] > 0) {
        object = [queue objectAtIndex:0];
    }
    [queLock unlock];
    return object;
}

- (BOOL)save {
    return [self writeToFile];
}

- (void) encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:queue forKey:@"queue"];
}

- (id) initWithCoder:(NSCoder *)coder {
    if (self = [super init])
    {
        queue = [coder decodeObjectForKey:@"queue"];
        queLock = [[NSRecursiveLock alloc] init];
    }

    return self;
}


@end
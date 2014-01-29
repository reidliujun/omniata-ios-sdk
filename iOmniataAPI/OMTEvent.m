#import "OMTEvent.h"


@implementation OMTEvent {

}
@synthesize data = _data;

- (id)initWithType:(int)type andData:(NSDictionary *)data {
    if (self = [super init])
    {
        _type = type;
        _data = data;//todo: Jijo: Not doing retain, asuming ARC takes care of this.
    }
    return self;
}


@end
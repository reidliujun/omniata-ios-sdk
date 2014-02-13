#import <Foundation/Foundation.h>

@interface OMTEvent : NSObject
{
    int _type;
    NSDictionary * _data;
}

@property(readonly, strong) id data;

-(id)initWithType:(int)type andData:(NSDictionary *)data;
@end
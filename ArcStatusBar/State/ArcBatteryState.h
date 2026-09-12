#import <Foundation/Foundation.h>

@interface ArcBatteryState : NSObject
+ (NSInteger)percentage;
+ (BOOL)charging;
@end

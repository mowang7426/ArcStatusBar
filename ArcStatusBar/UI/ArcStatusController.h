#import <UIKit/UIKit.h>

@class ArcBarView;

@interface ArcStatusController : NSObject
@property (nonatomic, strong, readonly) UIWindow *window;
@property (nonatomic, strong, readonly) ArcBarView *barView;

- (void)start;
- (void)stop;

@end

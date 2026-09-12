#import <UIKit/UIKit.h>

@class ArcMorphView;

@interface ArcStatusController : NSObject
@property (nonatomic, strong, readonly) UIWindow *window;
@property (nonatomic, strong, readonly) ArcMorphView *morphView;

- (void)start;
- (void)stop;
- (void)toggleDemo;

@end

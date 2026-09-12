#import <UIKit/UIKit.h>

@interface ArcMorphView : UIView

@property (nonatomic, assign, getter=isMorphActive) BOOL morphActive;

- (void)setMorphActive:(BOOL)active animated:(BOOL)animated;
- (void)playForward;
- (void)playReverse;

@end

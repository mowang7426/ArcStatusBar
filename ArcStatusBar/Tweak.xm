#import <UIKit/UIKit.h>
#import "UI/ArcStatusController.h"

static ArcStatusController *gArcController = nil;

%ctor {
    @autoreleasepool {
        if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (!gArcController) {
                gArcController = [[ArcStatusController alloc] init];
                [gArcController start];
            }
        });
    }
}

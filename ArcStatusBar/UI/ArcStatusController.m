#import "ArcStatusController.h"
#import "ArcMorphView.h"

@interface ArcStatusController ()
@property (nonatomic, strong, readwrite) UIWindow *window;
@property (nonatomic, strong, readwrite) ArcMorphView *morphView;
@property (nonatomic, strong) NSTimer *demoTimer;
@property (nonatomic, assign) BOOL running;
@end

@implementation ArcStatusController

- (void)start {
    if (self.running) return;
    self.running = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *scene = nil;
        for (UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
            if ([candidate isKindOfClass:UIWindowScene.class] &&
                candidate.activationState != UISceneActivationStateUnattached) {
                scene = (UIWindowScene *)candidate;
                break;
            }
        }

        if (!scene) {
            scene = UIApplication.sharedApplication.connectedScenes.anyObject;
        }

        CGRect bounds = scene ? scene.coordinateSpace.bounds : UIScreen.mainScreen.bounds;

        self.window = [[UIWindow alloc] initWithWindowScene:scene];
        self.window.frame = CGRectMake(0, 0, CGRectGetWidth(bounds), 58.0);
        self.window.windowLevel = UIWindowLevelStatusBar + 2.0;
        self.window.backgroundColor = UIColor.clearColor;
        self.window.opaque = NO;
        self.window.userInteractionEnabled = NO;

        UIViewController *vc = [UIViewController new];
        vc.view.backgroundColor = UIColor.clearColor;
        self.window.rootViewController = vc;

        // The visual occupies only the status-bar band and does not block touches.
        CGFloat w = MIN(230.0, CGRectGetWidth(bounds) - 24.0);
        self.morphView = [[ArcMorphView alloc] initWithFrame:CGRectMake(
            (CGRectGetWidth(bounds) - w) * 0.5,
            2.0,
            w,
            54.0
        )];

        [vc.view addSubview:self.morphView];
        [self.window makeKeyAndVisible];

        // Demo loop: forward -> hold -> reverse -> hold.
        [self scheduleDemo];
    });
}

- (void)scheduleDemo {
    [self.demoTimer invalidate];
    self.demoTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                       target:self
                                                     selector:@selector(toggleDemo)
                                                     userInfo:nil
                                                      repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.demoTimer forMode:NSRunLoopCommonModes];
}

- (void)toggleDemo {
    if (!self.morphView) return;

    if (self.morphView.isMorphActive) {
        [self.morphView playReverse];
    } else {
        [self.morphView playForward];
    }
}

- (void)stop {
    [self.demoTimer invalidate];
    self.demoTimer = nil;
    [self.window resignKeyWindow];
    self.window.hidden = YES;
    self.window = nil;
    self.morphView = nil;
    self.running = NO;
}

- (void)dealloc {
    [self.demoTimer invalidate];
}

@end

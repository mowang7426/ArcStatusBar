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

        // Do not assign `anyObject` directly to UIWindowScene under the
        // iOS 17 SDK's nullability/type checking. If SpringBoard has not
        // created an active window scene yet, retry on the next main-queue turn.
        if (!scene) {
            // NOTE: 原版用 UIScreen.mainScreen.windowScene 兜底, 但该属性是
            // 私有 API, SDK 16.5 中未声明, 直接编译报错。改为延迟 0.5s 重试,
            // SpringBoard 场景就绪后自动启动, 不依赖任何私有属性。
            self.running = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         (int64_t)(0.5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [self start];
            });
            return;
        }

        CGRect bounds = scene.coordinateSpace.bounds;

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

#import "ArcStatusController.h"
#import "ArcBarView.h"

@interface ArcStatusController ()
@property(nonatomic, strong, readwrite) UIWindow *window;
@property(nonatomic, strong, readwrite) ArcBarView *barView;
@property(nonatomic, assign) BOOL running;
@property(nonatomic, assign) NSInteger retryCount;
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
            // 场景未就绪 (SpringBoard/app 启动早期): 0.5s 后重试,
            // 最多 20 次 (~10s), 避免无 UIApplication 的 daemon 进程空转
            self.running = NO;
            self.retryCount++;
            if (self.retryCount >= 20) return;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         (int64_t)(0.5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [self start];
            });
            return;
        }

        CGRect bounds = scene.coordinateSpace.bounds;

        // 窗口只盖状态栏带 (含灵动岛两侧), 背景透明
        self.window = [[UIWindow alloc] initWithWindowScene:scene];
        self.window.frame = CGRectMake(0, 0, CGRectGetWidth(bounds), 44.0);
        self.window.windowLevel = UIWindowLevelStatusBar + 2.0;
        self.window.backgroundColor = UIColor.clearColor;
        self.window.opaque = NO;
        self.window.userInteractionEnabled = NO;
        self.window.hidden = NO;

        UIViewController *vc = [UIViewController new];
        vc.view.backgroundColor = UIColor.clearColor;
        self.window.rootViewController = vc;

        // 极简点阵视图: 右对齐贴在原生电池/信号/WiFi 图标上方
        self.barView = [[ArcBarView alloc] initWithFrame:
                        CGRectMake(0, 6.0, CGRectGetWidth(bounds), 32.0)];
        [vc.view addSubview:self.barView];
        [self.window makeKeyAndVisible];

        // 启动后 0.6s 淡入形变, 之后保持极简形态 (不循环演示)
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(0.6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [weakSelf.barView setActive:YES animated:YES];
        });
    });
}

- (void)stop {
    self.window.hidden = YES;
    self.window = nil;
    self.barView = nil;
    self.running = NO;
}

@end

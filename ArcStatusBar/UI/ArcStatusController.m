#import "ArcStatusController.h"
#import "ArcMorphView.h"
#import "../State/ArcNetworkState.h"
#import "../State/ArcBatteryState.h"

@interface ArcStatusController ()
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) UILabel *timeLabel;
@property(nonatomic, strong) UILabel *signalLabel;
@property(nonatomic, strong) UILabel *batteryLabel;
@property(nonatomic, strong) ArcMorphView *morphView;
@property(nonatomic, strong) NSTimer *timer;
@end

@implementation ArcStatusController

+ (instancetype)sharedController {
    static ArcStatusController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [ArcStatusController new];
    });
    return controller;
}

- (UIWindowScene *)activeScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;

        if (scene.activationState == UISceneActivationStateForegroundActive ||
            scene.activationState == UISceneActivationStateForegroundInactive) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

- (void)start {
    if (self.window) return;

    UIWindowScene *scene = [self activeScene];
    if (!scene) return;

    self.window = [[UIWindow alloc] initWithWindowScene:scene];
    self.window.backgroundColor = UIColor.clearColor;
    self.window.windowLevel = UIWindowLevelStatusBar + 2.0;
    self.window.userInteractionEnabled = NO;

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.clearColor;
    self.window.rootViewController = vc;

    CGRect b = scene.coordinateSpace.bounds;
    CGFloat top = scene.statusBarManager.statusBarFrame.size.height;
    CGFloat y = MAX(2.0, top - 5.0);

    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, y, 70, 28)];
    self.timeLabel.textColor = UIColor.whiteColor;
    self.timeLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightSemibold];
    [vc.view addSubview:self.timeLabel];

    self.signalLabel = [[UILabel alloc] initWithFrame:CGRectMake(b.size.width - 172, y, 52, 28)];
    self.signalLabel.text = @"▮▮▮▮";
    self.signalLabel.textColor = UIColor.whiteColor;
    self.signalLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.signalLabel.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:self.signalLabel];

    self.batteryLabel = [[UILabel alloc] initWithFrame:CGRectMake(b.size.width - 64, y, 58, 28)];
    self.batteryLabel.textColor = UIColor.whiteColor;
    self.batteryLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.batteryLabel.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:self.batteryLabel];

    self.morphView = [[ArcMorphView alloc] initWithFrame:
                      CGRectMake(b.size.width / 2.0 - 45,
                                 y - 5,
                                 90,
                                 90)];
    [vc.view addSubview:self.morphView];

    [self update];

    self.window.hidden = NO;

    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                   repeats:YES
                                                     block:^(NSTimer *timer) {
        [weakSelf update];
    }];

    /*
     * Demo trigger:
     * periodically enters/exits the morph state so the animation can be
     * visually tested without requiring private SpringBoard APIs.
     */
    [self performSelector:@selector(toggleDemo)
               withObject:nil
               afterDelay:3.0];
}

- (void)toggleDemo {
    if (!self.morphView) return;

    [self.morphView setArcMode:!self.morphView.arcMode animated:YES];

    [self performSelector:@selector(toggleDemo)
               withObject:nil
               afterDelay:self.morphView.arcMode ? 4.0 : 3.0];
}

- (void)update {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"HH:mm";
    formatter.locale = [NSLocale currentLocale];

    self.timeLabel.text = [formatter stringFromDate:NSDate.date];

    self.signalLabel.text = [ArcNetworkState signalVisual];

    NSInteger battery = [ArcBatteryState percentage];
    BOOL charging = [ArcBatteryState charging];

    self.batteryLabel.text = charging
        ? [NSString stringWithFormat:@"%ld%%⚡︎", (long)battery]
        : [NSString stringWithFormat:@"%ld%%", (long)battery];

    self.morphView.centerLabel.text = [ArcNetworkState radioLabel];
}

@end

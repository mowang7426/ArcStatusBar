#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

static UIView *CSBContainer;
static UIView *CSBWiFiDots;
static UILabel *CSBSignalLabel;
static UILabel *CSBWiFiLabel;
static UIView *CSBBattery;
static UIView *CSBBatteryFill;

static UIWindow *CSBKeyWindow(void) {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIWindow *window in app.windows) {
        if (!window.hidden && window.alpha > 0.01 &&
            window.windowLevel == UIWindowLevelNormal) {
            return window;
        }
    }
    return nil;
}

static void CSBBatteryChanged(void) {
    if (!CSBBatteryFill) return;

    CGFloat level = UIDevice.currentDevice.batteryLevel;
    if (level < 0.0) return;

    CGRect frame = CSBBatteryFill.frame;
    frame.size.width = MAX(0.0, MIN(20.0, 20.0 * level));

    [UIView animateWithDuration:0.18 animations:^{
        CSBBatteryFill.frame = frame;
    }];
}

static void CSBCreateWiFiDots(void) {
    if (!CSBContainer || CSBWiFiDots) return;

    CSBWiFiDots = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 10)];
    CSBWiFiDots.userInteractionEnabled = NO;

    for (NSInteger i = 0; i < 4; i++) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(i * 8.0, 3, 5, 5)];
        dot.backgroundColor = UIColor.whiteColor;
        dot.layer.cornerRadius = 2.5;
        dot.alpha = 0.25;
        [CSBWiFiDots addSubview:dot];

        [UIView animateWithDuration:0.5
                              delay:i * 0.08
                            options:UIViewAnimationOptionRepeat |
                                    UIViewAnimationOptionAutoreverse |
                                    UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            dot.alpha = 1.0;
        } completion:nil];
    }

    [CSBContainer addSubview:CSBWiFiDots];
}

static void CSBCreateUI(void) {
    if (CSBContainer) return;

    UIWindow *window = CSBKeyWindow();
    if (!window) return;

    CGFloat width = UIScreen.mainScreen.bounds.size.width;

    CSBContainer = [[UIView alloc] initWithFrame:CGRectMake(20, 8, width - 40, 24)];
    CSBContainer.backgroundColor = UIColor.clearColor;
    CSBContainer.userInteractionEnabled = NO;
    CSBContainer.layer.zPosition = 9999.0;
    [window addSubview:CSBContainer];

    CSBSignalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 25, 20)];
    CSBSignalLabel.text = @"▮▮▮";
    CSBSignalLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    CSBSignalLabel.textColor = UIColor.whiteColor;
    [CSBContainer addSubview:CSBSignalLabel];

    CSBWiFiLabel = [[UILabel alloc] initWithFrame:CGRectMake(34, 0, 25, 20)];
    CSBWiFiLabel.text = @"⌁";
    CSBWiFiLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    CSBWiFiLabel.textColor = UIColor.whiteColor;
    [CSBContainer addSubview:CSBWiFiLabel];

    CSBCreateWiFiDots();
    CSBWiFiDots.frame = CGRectMake(60, 5, 32, 10);

    CSBBattery = [[UIView alloc] initWithFrame:CGRectMake(width - 70, 6, 24, 11)];
    CSBBattery.backgroundColor = UIColor.clearColor;
    CSBBattery.layer.cornerRadius = 5.5;
    CSBBattery.layer.borderWidth = 1.0;
    CSBBattery.layer.borderColor = UIColor.whiteColor.CGColor;
    [CSBContainer addSubview:CSBBattery];

    CSBBatteryFill = [[UIView alloc] initWithFrame:CGRectMake(2, 2, 20, 7)];
    CSBBatteryFill.backgroundColor = UIColor.whiteColor;
    CSBBatteryFill.layer.cornerRadius = 3.5;
    [CSBBattery addSubview:CSBBatteryFill];

    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    CSBBatteryChanged();
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        CSBCreateUI();
    });

    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIDeviceBatteryLevelDidChangeNotification
        object:nil
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *note) {
            CSBBatteryChanged();
        }];
}

%end

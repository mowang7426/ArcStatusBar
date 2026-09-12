//
//  Tweak.xm — ArcStatusBar v3.1
//  机制复刻参考插件 CAiPhoneDuoStatus (二进制 selector/类名实证):
//   1) hook 双套状态栏类 (_UIStatusBar* iOS16 / STUIStatusBar* iOS17) 的
//      全部数据/位置 setter: setNumberOfActiveBars: setChargePercent:
//      setChargingState: setBattery: setCellular: setNetwork:
//      setBatteryFrame: setCellularFrame: setNetworkFrame:
//   2) setter 中: 记录真实数据 + 记录原生图标 frame + 隐藏原生图标
//   3) ArcNativeState 挂在 ForegroundView 上, drawRect 用记录的 frame 原位重绘
//   4) ForegroundView setApplyingLayout: + layoutSubviews 双保险触发挂载
//
#import <UIKit/UIKit.h>
#import "Core/ArcNativeState.h"

// ---------------------------------------------------------------------------
// 双套私有类声明
// ---------------------------------------------------------------------------
@interface _UIStatusBarCellularSignalView : UIView
- (void)setNumberOfActiveBars:(NSInteger)bars;
- (void)setCellular:(id)cellular;
- (void)setCellularFrame:(CGRect)frame;
@end
@interface STUIStatusBarCellularSignalView : UIView
- (void)setNumberOfActiveBars:(NSInteger)bars;
- (void)setCellular:(id)cellular;
- (void)setCellularFrame:(CGRect)frame;
@end
@interface _UIStatusBarWifiSignalView : UIView
- (void)setNetwork:(id)network;
- (void)setNetworkFrame:(CGRect)frame;
@end
@interface STUIStatusBarWifiSignalView : UIView
- (void)setNetwork:(id)network;
- (void)setNetworkFrame:(CGRect)frame;
@end
@interface _UIBatteryView : UIView
- (void)setBattery:(id)battery;
- (void)setChargePercent:(CGFloat)percent;
- (void)setChargingState:(NSInteger)state;
- (void)setBatteryFrame:(CGRect)frame;
@end
@interface _UIStaticBatteryView : UIView
- (void)setBattery:(id)battery;
- (void)setChargePercent:(CGFloat)percent;
- (void)setChargingState:(NSInteger)state;
- (void)setBatteryFrame:(CGRect)frame;
@end
@interface STUIStatusBarStaticBatteryView : UIView
- (void)setBattery:(id)battery;
- (void)setChargePercent:(CGFloat)percent;
- (void)setChargingState:(NSInteger)state;
- (void)setBatteryFrame:(CGRect)frame;
@end
@interface _UIStatusBarCellularNetworkTypeView : UIView
- (void)setCellular:(id)cellular;
- (void)setCellularFrame:(CGRect)frame;
@end
@interface STUIStatusBarCellularNetworkTypeView : UIView
- (void)setCellular:(id)cellular;
- (void)setCellularFrame:(CGRect)frame;
@end
@interface _UIStatusBarForegroundView : UIView
- (void)setApplyingLayout:(BOOL)applying;
@end
@interface STUIStatusBarForegroundView : UIView
- (void)setApplyingLayout:(BOOL)applying;
@end

// ---------------------------------------------------------------------------
// 共享处理函数 (每个 %hook 块内薄封装调用)
// ---------------------------------------------------------------------------
static void ASB_LOG_HIT(NSString *what) {
    static NSMutableSet *logged;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ logged = [NSMutableSet set]; });
    if (![logged containsObject:what]) {
        [logged addObject:what];
        NSLog(@"[ArcStatusBar] HIT %@", what);
    }
}

// 递归隐藏宿主树中所有原生图标 (信号/WiFi/电池/5G 标签可能在深层子视图)
static void ASB_HideTargets(UIView *root) {
    for (UIView *v in root.subviews) {
        NSString *c = NSStringFromClass(v.class);
        if ([c containsString:@"Signal"] ||
            [c containsString:@"Wifi"] ||
            [c containsString:@"WiFi"] ||
            [c containsString:@"Battery"] ||
            [c containsString:@"NetworkType"]) {
            v.hidden = YES;
        }
        ASB_HideTargets(v);
    }
}

// 向上找状态栏根容器 (含 StatusBar 且非 Foreground/Item 的视图)
static UIView *ASB_FindStatusBarContainer(UIView *v) {
    UIView *cur = v;
    UIView *last = v;
    while (cur) {
        NSString *c = NSStringFromClass(cur.class);
        if ([c containsString:@"StatusBar"] &&
            ![c containsString:@"Foreground"] &&
            ![c containsString:@"Item"]) {
            return cur;
        }
        last = cur;
        cur = cur.superview;
    }
    return last;
}

// 挂载 + 递归隐藏 + 重绘 (异步, 不在 setter 调用栈内动视图层级)
static void ASB_EnsureMounted(UIView *v) {
    __weak UIView *weakV = v;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *vv = weakV;
        if (!vv || !vv.superview) return;
        UIView *host = ASB_FindStatusBarContainer(vv);
        if (!host) return;
        [[ArcNativeState sharedState] attachToHost:host];
        ASB_HideTargets(host);
        [[ArcNativeState sharedState] setNeedsDisplay];
    });
}

static void ASB_OnSignalBars(UIView *self, NSInteger bars) {
    ASB_LOG_HIT(NSStringFromClass(self.class));
    [ArcNativeState sharedState].activeBars = bars;
    self.hidden = YES;
    ASB_EnsureMounted(self);
}

static void ASB_OnSignalData(UIView *self) {
    self.hidden = YES;
    ASB_EnsureMounted(self);
}

static void ASB_OnSignalFrame(UIView *self, CGRect f) {
    [ArcNativeState sharedState].signalView = self;
    [ArcNativeState sharedState].signalFrame = f;
}

static void ASB_OnWifiData(UIView *self) {
    self.hidden = YES;
    ASB_EnsureMounted(self);
}

static void ASB_OnWifiFrame(UIView *self, CGRect f) {
    [ArcNativeState sharedState].wifiView = self;
    [ArcNativeState sharedState].wifiFrame = f;
}

static void ASB_OnBatteryData(UIView *self) {
    self.hidden = YES;
    ASB_EnsureMounted(self);
}

static void ASB_OnChargePercent(UIView *self, CGFloat percent) {
    ASB_LOG_HIT(NSStringFromClass(self.class));
    [ArcNativeState sharedState].chargePercent = (NSInteger)percent;
    self.hidden = YES;
    ASB_EnsureMounted(self);
}

static void ASB_OnChargingState(NSInteger state) {
    [ArcNativeState sharedState].charging = (state != 0);
}

static void ASB_OnBatteryFrame(UIView *self, CGRect f) {
    [ArcNativeState sharedState].batteryView = self;
    [ArcNativeState sharedState].batteryFrame = f;
}

static void ASB_OnNetType(UIView *self) {
    self.hidden = YES;
    ASB_EnsureMounted(self);
}

// 布局完成回调: 延迟到主队列下一轮再挂载/隐藏/重绘
// 关键: 绝不在 setApplyingLayout: 调用栈内 addSubview/改 hidden,
//       否则会触发布局重入 -> 控制中心卡死/SpringBoard 冻结
static void ASB_OnLayoutDone(UIView *fg) {
    static NSMutableSet *done;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ done = [NSMutableSet set]; });

    NSString *key = NSStringFromClass(fg.class);
    if (![done containsObject:key]) {
        [done addObject:key];
        NSLog(@"[ArcStatusBar] layoutDone %@", key);
        ASB_ShowBanner([NSString stringWithFormat:@"ArcStatusBar hook ✓ %@", key]);
    }

    __weak UIView *weakFg = fg;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *host = weakFg;
        if (!host) return;
        [[ArcNativeState sharedState] attachToHost:host];
        // 递归隐藏全部原生图标 (异步, 不在布局栈内)
        ASB_HideTargets(host);
        [[ArcNativeState sharedState] setNeedsDisplay];
    });
}

// ---------------------------------------------------------------------------
// Hook: 信号
// ---------------------------------------------------------------------------
%hook _UIStatusBarCellularSignalView
- (void)setNumberOfActiveBars:(NSInteger)bars {
    %orig;
    ASB_OnSignalBars(self, bars);
}
- (void)setCellular:(id)cellular {
    %orig;
    ASB_OnSignalData(self);
}
- (void)setCellularFrame:(CGRect)frame {
    %orig;
    ASB_OnSignalFrame(self, frame);
}
%end

%hook STUIStatusBarCellularSignalView
- (void)setNumberOfActiveBars:(NSInteger)bars {
    %orig;
    ASB_OnSignalBars(self, bars);
}
- (void)setCellular:(id)cellular {
    %orig;
    ASB_OnSignalData(self);
}
- (void)setCellularFrame:(CGRect)frame {
    %orig;
    ASB_OnSignalFrame(self, frame);
}
%end

// ---------------------------------------------------------------------------
// Hook: WiFi
// ---------------------------------------------------------------------------
%hook _UIStatusBarWifiSignalView
- (void)setNetwork:(id)network {
    %orig;
    ASB_OnWifiData(self);
}
- (void)setNetworkFrame:(CGRect)frame {
    %orig;
    ASB_OnWifiFrame(self, frame);
}
%end

%hook STUIStatusBarWifiSignalView
- (void)setNetwork:(id)network {
    %orig;
    ASB_OnWifiData(self);
}
- (void)setNetworkFrame:(CGRect)frame {
    %orig;
    ASB_OnWifiFrame(self, frame);
}
%end

// ---------------------------------------------------------------------------
// Hook: 电池
// ---------------------------------------------------------------------------
%hook _UIBatteryView
- (void)setBattery:(id)battery {
    %orig;
    ASB_OnBatteryData(self);
}
- (void)setChargePercent:(CGFloat)percent {
    %orig;
    ASB_OnChargePercent(self, percent);
}
- (void)setChargingState:(NSInteger)state {
    %orig;
    ASB_OnChargingState(state);
}
- (void)setBatteryFrame:(CGRect)frame {
    %orig;
    ASB_OnBatteryFrame(self, frame);
}
%end

%hook _UIStaticBatteryView
- (void)setBattery:(id)battery {
    %orig;
    ASB_OnBatteryData(self);
}
- (void)setChargePercent:(CGFloat)percent {
    %orig;
    ASB_OnChargePercent(self, percent);
}
- (void)setChargingState:(NSInteger)state {
    %orig;
    ASB_OnChargingState(state);
}
- (void)setBatteryFrame:(CGRect)frame {
    %orig;
    ASB_OnBatteryFrame(self, frame);
}
%end

%hook STUIStatusBarStaticBatteryView
- (void)setBattery:(id)battery {
    %orig;
    ASB_OnBatteryData(self);
}
- (void)setChargePercent:(CGFloat)percent {
    %orig;
    ASB_OnChargePercent(self, percent);
}
- (void)setChargingState:(NSInteger)state {
    %orig;
    ASB_OnChargingState(state);
}
- (void)setBatteryFrame:(CGRect)frame {
    %orig;
    ASB_OnBatteryFrame(self, frame);
}
%end

// ---------------------------------------------------------------------------
// Hook: 5G 标签 (隐藏)
// ---------------------------------------------------------------------------
%hook _UIStatusBarCellularNetworkTypeView
- (void)setCellular:(id)cellular {
    %orig;
    ASB_OnNetType(self);
}
- (void)setCellularFrame:(CGRect)frame {
    %orig;
    ASB_OnNetType(self);
}
%end

%hook STUIStatusBarCellularNetworkTypeView
- (void)setCellular:(id)cellular {
    %orig;
    ASB_OnNetType(self);
}
- (void)setCellularFrame:(CGRect)frame {
    %orig;
    ASB_OnNetType(self);
}
%end

// ---------------------------------------------------------------------------
// Hook: ForegroundView (布局完成 -> 异步挂载 / 隐藏 / 重绘)
// 只 hook setApplyingLayout: (对齐参考插件), 不 hook layoutSubviews
// ---------------------------------------------------------------------------
%hook _UIStatusBarForegroundView
- (void)setApplyingLayout:(BOOL)applying {
    %orig;
    if (!applying) {
        ASB_OnLayoutDone(self);
    }
}
%end

%hook STUIStatusBarForegroundView
- (void)setApplyingLayout:(BOOL)applying {
    %orig;
    if (!applying) {
        ASB_OnLayoutDone(self);
    }
}
%end

// ---------------------------------------------------------------------------
// 自检横幅: 装上后锁屏 3 秒内屏幕中央弹提示 = 插件已加载
// 不弹 = dylib 未加载 (安装/编译问题), 一眼定位
// ---------------------------------------------------------------------------
static void ASB_ShowBanner(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect sb = [UIScreen mainScreen].bounds;
        UIWindow *win = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 56)];
        win.center = CGPointMake(CGRectGetMidX(sb), CGRectGetMidY(sb) - 120);
        win.windowLevel = 2000.0;
        win.backgroundColor = [UIColor colorWithWhite:0 alpha:0.88];
        win.layer.cornerRadius = 14;
        win.layer.masksToBounds = YES;
        win.userInteractionEnabled = NO;
        UILabel *l = [[UILabel alloc] initWithFrame:win.bounds];
        l.text = msg;
        l.textColor = UIColor.whiteColor;
        l.textAlignment = NSTextAlignmentCenter;
        l.font = [UIFont boldSystemFontOfSize:15];
        [win addSubview:l];
        win.hidden = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            win.hidden = YES;
        });
    });
}

// ---------------------------------------------------------------------------
// 诊断: %ctor 检查目标类是否存在 + 控制中心收起刷新 + 自检横幅
// ---------------------------------------------------------------------------
%ctor {
    @autoreleasepool {
        NSArray<NSString *> *candidates = @[
            @"STUIStatusBarCellularSignalView",
            @"STUIStatusBarWifiSignalView",
            @"STUIStatusBarStaticBatteryView",
            @"STUIStatusBarCellularNetworkTypeView",
            @"STUIStatusBarForegroundView",
            @"_UIStatusBarCellularSignalView",
            @"_UIStatusBarWifiSignalView",
            @"_UIBatteryView",
            @"_UIStaticBatteryView",
            @"_UIStatusBarCellularNetworkTypeView",
            @"_UIStatusBarForegroundView",
        ];
        for (NSString *name in candidates) {
            NSLog(@"[ArcStatusBar] class %@ %@",
                  name, NSClassFromString(name) ? @"EXISTS" : @"missing");
        }

        [[NSNotificationCenter defaultCenter]
            addObserverForName:@"SBControlCenterControllerDidDismissNotification"
                        object:nil queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
            [[ArcNativeState sharedState] setNeedsDisplay];
        }];

        ASB_ShowBanner(@"ArcStatusBar loaded ✓");
    }
}

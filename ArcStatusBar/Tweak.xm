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

static void ASB_OnSignalBars(UIView *self, NSInteger bars) {
    ASB_LOG_HIT(NSStringFromClass(self.class));
    [ArcNativeState sharedState].activeBars = bars;
    self.hidden = YES;
}

static void ASB_OnSignalData(UIView *self) {
    self.hidden = YES;
}

static void ASB_OnSignalFrame(UIView *self, CGRect f) {
    [ArcNativeState sharedState].signalView = self;
    [ArcNativeState sharedState].signalFrame = f;
}

static void ASB_OnWifiData(UIView *self) {
    self.hidden = YES;
}

static void ASB_OnWifiFrame(UIView *self, CGRect f) {
    [ArcNativeState sharedState].wifiView = self;
    [ArcNativeState sharedState].wifiFrame = f;
}

static void ASB_OnBatteryData(UIView *self) {
    self.hidden = YES;
}

static void ASB_OnChargePercent(UIView *self, CGFloat percent) {
    ASB_LOG_HIT(NSStringFromClass(self.class));
    [ArcNativeState sharedState].chargePercent = (NSInteger)percent;
    self.hidden = YES;
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
}

// 布局完成: 挂载 + 隐藏兜底 + 重绘
static void ASB_OnLayoutDone(UIView *fg) {
    ASB_LOG_HIT(NSStringFromClass(fg.class));
    [[ArcNativeState sharedState] attachToHost:fg];
    for (UIView *v in fg.subviews) {
        NSString *c = NSStringFromClass(v.class);
        if ([c containsString:@"Signal"] || [c containsString:@"Wifi"] ||
            [c containsString:@"WiFi"] || [c containsString:@"Battery"] ||
            [c containsString:@"NetworkType"]) {
            v.hidden = YES;
        }
    }
    [[ArcNativeState sharedState] setNeedsDisplay];
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
// Hook: ForegroundView (布局完成 -> 挂载 / 隐藏 / 重绘)
// ---------------------------------------------------------------------------
%hook _UIStatusBarForegroundView
- (void)setApplyingLayout:(BOOL)applying {
    %orig;
    if (!applying) {
        ASB_OnLayoutDone(self);
    }
}
- (void)layoutSubviews {
    %orig;
    [[ArcNativeState sharedState] attachToHost:self];
    [[ArcNativeState sharedState] setNeedsDisplay];
}
%end

%hook STUIStatusBarForegroundView
- (void)setApplyingLayout:(BOOL)applying {
    %orig;
    if (!applying) {
        ASB_OnLayoutDone(self);
    }
}
- (void)layoutSubviews {
    %orig;
    [[ArcNativeState sharedState] attachToHost:self];
    [[ArcNativeState sharedState] setNeedsDisplay];
}
%end

// ---------------------------------------------------------------------------
// 诊断: %ctor 检查目标类是否存在 + 控制中心收起刷新
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
    }
}

//
//  Tweak.xm — ArcStatusBar v3
//  机制复刻参考插件 CAiPhoneDuoStatus:
//   1) hook 双套状态栏类 (iOS16 _UIStatusBar* + iOS17 STUIStatusBar*) 的
//      真实数据 setter: setNumberOfActiveBars:(信号格数) setChargePercent:(电池)
//   2) 隐藏原生图标 (setHidden:YES)
//   3) ArcNativeState 挂在 ForegroundView 上原位用 CGContext 重绘极简图形
//   4) setApplyingLayout: 完成后统一挂载/隐藏/重绘; 控制中心收起时刷新
//
#import <UIKit/UIKit.h>
#import "Core/ArcNativeState.h"

// ---------------------------------------------------------------------------
// 双套私有类声明
// ---------------------------------------------------------------------------
// iOS 16 (UIKit, app/SpringBoard 均有) + iOS 17 (ST, SpringBoard)
@interface _UIStatusBarCellularSignalView : UIView
- (void)setNumberOfActiveBars:(NSInteger)bars;
@end
@interface STUIStatusBarCellularSignalView : UIView
- (void)setNumberOfActiveBars:(NSInteger)bars;
@end

@interface _UIStatusBarWifiSignalView : UIView
- (void)setNetwork:(id)network;
@end
@interface STUIStatusBarWifiSignalView : UIView
- (void)setNetwork:(id)network;
@end

@interface _UIBatteryView : UIView
- (void)setChargePercent:(CGFloat)percent;
- (void)setChargingState:(NSInteger)state;
@end
@interface _UIStaticBatteryView : UIView
- (void)setChargePercent:(CGFloat)percent;
- (void)setChargingState:(NSInteger)state;
@end
@interface STUIStatusBarStaticBatteryView : UIView
- (void)setChargePercent:(CGFloat)percent;
- (void)setChargingState:(NSInteger)state;
@end

@interface _UIStatusBarCellularNetworkTypeView : UIView
- (void)setCellular:(id)cellular;
@end
@interface STUIStatusBarCellularNetworkTypeView : UIView
- (void)setCellular:(id)cellular;
@end

@interface _UIStatusBarForegroundView : UIView
- (void)setApplyingLayout:(BOOL)applying;
@end
@interface STUIStatusBarForegroundView : UIView
- (void)setApplyingLayout:(BOOL)applying;
@end

// ---------------------------------------------------------------------------
// 工具: 递归隐藏原生图标视图 (按类名关键词)
// ---------------------------------------------------------------------------
static void ASB_HideNative(UIView *root) {
    for (UIView *v in root.subviews) {
        NSString *cls = NSStringFromClass(v.class);
        if ([cls containsString:@"Signal"] ||
            [cls containsString:@"Wifi"] ||
            [cls containsString:@"WiFi"] ||
            [cls containsString:@"Battery"] ||
            [cls containsString:@"NetworkType"]) {
            v.hidden = YES;
        }
        ASB_HideNative(v);
    }
}

static void ASB_Refresh(UIView *host) {
    ArcNativeState *state = [ArcNativeState sharedState];
    [state attachToHost:host];
    ASB_HideNative(host);
    [state setNeedsDisplay];
}

// ---------------------------------------------------------------------------
// Hook: 信号强度 (4 点中点亮数量)
// ---------------------------------------------------------------------------
%hook _UIStatusBarCellularSignalView
- (void)setNumberOfActiveBars:(NSInteger)bars {
    %orig;
    [ArcNativeState sharedState].activeBars = bars;
}
%end

%hook STUIStatusBarCellularSignalView
- (void)setNumberOfActiveBars:(NSInteger)bars {
    %orig;
    [ArcNativeState sharedState].activeBars = bars;
}
%end

// ---------------------------------------------------------------------------
// Hook: 电池 (百分比 + 充电状态)
// ---------------------------------------------------------------------------
%hook _UIBatteryView
- (void)setChargePercent:(CGFloat)percent {
    %orig;
    [ArcNativeState sharedState].chargePercent = (NSInteger)percent;
}
- (void)setChargingState:(NSInteger)state {
    %orig;
    [ArcNativeState sharedState].charging = (state != 0);
}
%end

%hook _UIStaticBatteryView
- (void)setChargePercent:(CGFloat)percent {
    %orig;
    [ArcNativeState sharedState].chargePercent = (NSInteger)percent;
}
- (void)setChargingState:(NSInteger)state {
    %orig;
    [ArcNativeState sharedState].charging = (state != 0);
}
%end

%hook STUIStatusBarStaticBatteryView
- (void)setChargePercent:(CGFloat)percent {
    %orig;
    [ArcNativeState sharedState].chargePercent = (NSInteger)percent;
}
- (void)setChargingState:(NSInteger)state {
    %orig;
    [ArcNativeState sharedState].charging = (state != 0);
}
%end

// ---------------------------------------------------------------------------
// Hook: WiFi / 5G (数据入口, 数据对象不解析, 仅触发隐藏与重绘)
// ---------------------------------------------------------------------------
%hook _UIStatusBarWifiSignalView
- (void)setNetwork:(id)network {
    %orig;
    [ArcNativeState sharedState].networkUpdated = YES;
}
%end

%hook STUIStatusBarWifiSignalView
- (void)setNetwork:(id)network {
    %orig;
    [ArcNativeState sharedState].networkUpdated = YES;
}
%end

%hook _UIStatusBarCellularNetworkTypeView
- (void)setCellular:(id)cellular {
    %orig;
    [ArcNativeState sharedState].networkUpdated = YES;
}
%end

%hook STUIStatusBarCellularNetworkTypeView
- (void)setCellular:(id)cellular {
    %orig;
    [ArcNativeState sharedState].networkUpdated = YES;
}
%end

// ---------------------------------------------------------------------------
// Hook: ForegroundView 布局完成 -> 挂载 / 隐藏 / 重绘
// ---------------------------------------------------------------------------
%hook _UIStatusBarForegroundView
- (void)setApplyingLayout:(BOOL)applying {
    %orig;
    if (!applying) {
        ASB_Refresh(self);
    }
}
%end

%hook STUIStatusBarForegroundView
- (void)setApplyingLayout:(BOOL)applying {
    %orig;
    if (!applying) {
        ASB_Refresh(self);
    }
}
%end

// ---------------------------------------------------------------------------
// 控制中心收起时刷新 (复刻参考插件)
// ---------------------------------------------------------------------------
%ctor {
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter]
            addObserverForName:@"SBControlCenterControllerDidDismissNotification"
                        object:nil queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
            UIView *host = [ArcNativeState sharedState].superview;
            if (host) [ArcNativeState sharedState].frame = host.bounds;
            [[ArcNativeState sharedState] setNeedsDisplay];
        }];
    }
}

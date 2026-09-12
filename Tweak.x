//
//  Tweak.x
//  ArcStatusBar — 极简点阵状态栏
//
//  原理: iOS 13+ 状态栏图标视图 — iOS 16 为 _UIStatusBar*View 系列,
//        iOS 17 整体改名为 STUIStatusBar*View 系列 (电池一直是 _UIBatteryView,
//        iOS 17 为 STUIStatusBarStaticBatteryView)。
//  这里对两套类都做 hook (参考 CAiPhoneDuoStatus 的双类兼容写法),
//    hook 各 item view 的 layoutSubviews, 隐藏原生图标, 叠加自定义
//    "4点信号 + 弧形WiFi + 线性电池", 数据用 KVC 多 key 读取真实值。
//
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "ArcStatusBarViews.h"

static const void *kSigKey  = &kSigKey;
static const void *kWifiKey = &kWifiKey;
static const void *kBatKey  = &kBatKey;

// ---------------------------------------------------------------------------
// 私有类声明 (双套), 让编译器知道这些是 UIView 子类并可访问其属性/方法
// ---------------------------------------------------------------------------
// iOS 16 系列
@interface _UIStatusBarCellularSignalView : UIView @end
@interface _UIStatusBarWifiSignalView : UIView @end
@interface _UIBatteryView : UIView @end
@interface _UIStaticBatteryView : UIView @end
@interface _UIStatusBarForegroundView : UIView
- (void)setApplyingLayout:(BOOL)applying;
@end
// iOS 17 (ST) 系列
@interface STUIStatusBarCellularSignalView : UIView @end
@interface STUIStatusBarWifiSignalView : UIView @end
@interface STUIStatusBarStaticBatteryView : UIView @end
@interface STUIStatusBarForegroundView : UIView
- (void)setApplyingLayout:(BOOL)applying;
@end

// 记录最近一次创建的实例, 供 SpringBoard 启动动画使用
static ASBDotSignalView   *gSigView;
static ASBArcWifiView     *gWifiView;
static ASBLineBatteryView *gBatView;

static UIColor *ASBInk(UIView *host) {
    return host.tintColor ?: [UIColor blackColor];
}

// 把自定义视图挂到 item view 上, 并隐藏原生图标
static void ASBInstall(UIView *host, UIView *custom, const void *key) {
    UIView *old = objc_getAssociatedObject(host, key);
    if (old && old != custom) {
        [old removeFromSuperview];
    }
    if (custom.superview != host) {
        custom.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [host addSubview:custom];
        objc_setAssociatedObject(host, key, custom, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    custom.frame = host.bounds;
    // 隐藏原生图标层 (保留布局, 只隐藏显示)
    for (UIView *sub in host.subviews) {
        if (sub != custom) sub.alpha = 0.0;
    }
}

// KVC 多 key 读取整数 (ST 类用 numberOfActiveBars, 旧类用 _signalStrengthBars)
static NSInteger ASBReadInt(UIView *v, NSArray<NSString *> *keys, NSInteger fallback) {
    for (NSString *k in keys) {
        @try {
            NSNumber *n = [v valueForKey:k];
            if (n) return n.integerValue;
        } @catch (NSException *e) { }
    }
    return fallback;
}

// 读取电量 (返回 0.0~1.0)。chargePercent 可能是 0-100 或 0-1, 统一归一化
static CGFloat ASBReadCapacity(UIView *v) {
    @try {
        NSNumber *n = [v valueForKey:@"chargePercent"];
        if (n) {
            double x = n.doubleValue;
            if (x > 1.0) x /= 100.0;
            return (CGFloat)MAX(0.0, MIN(1.0, x));
        }
    } @catch (NSException *e) { }
    @try {
        NSNumber *n = [v valueForKey:@"capacity"];
        if (n) return (CGFloat)MAX(0.0, MIN(1.0, n.doubleValue));
    } @catch (NSException *e) { }
    return 0.8;
}

#pragma mark - 通用布局处理 (供双套类共用)

static void ASBSignalLayout(UIView *self) {
    ASBDotSignalView *v = objc_getAssociatedObject(self, kSigKey);
    if (!v) {
        v = [[ASBDotSignalView alloc] initWithFrame:self.bounds];
        ASBInstall(self, v, kSigKey);
        gSigView = v;
    }
    v.frame = self.bounds;
    [v setInkColor:ASBInk(self)];
    NSInteger bars = ASBReadInt(self, @[@"numberOfActiveBars", @"_signalStrengthBars"], 3);
    [v setBars:MAX(0, MIN(4, bars)) animated:NO];
}

static void ASBWifiLayout(UIView *self) {
    ASBArcWifiView *v = objc_getAssociatedObject(self, kWifiKey);
    if (!v) {
        v = [[ASBArcWifiView alloc] initWithFrame:self.bounds];
        ASBInstall(self, v, kWifiKey);
        gWifiView = v;
    }
    v.frame = self.bounds;
    [v setInkColor:ASBInk(self)];
    NSInteger bars = ASBReadInt(self, @[@"numberOfActiveBars", @"_signalStrengthBars"], 3);
    [v setBars:MAX(0, MIN(3, bars)) animated:NO];
}

static void ASBBatteryLayout(UIView *self) {
    ASBLineBatteryView *v = objc_getAssociatedObject(self, kBatKey);
    if (!v) {
        v = [[ASBLineBatteryView alloc] initWithFrame:self.bounds];
        ASBInstall(self, v, kBatKey);
        gBatView = v;
    }
    v.frame = self.bounds;
    [v setInkColor:ASBInk(self)];
    [v setCapacity:ASBReadCapacity(self) animated:NO];
}

#pragma mark - 蜂窝信号: 4 点阵 (双套类)

%hook _UIStatusBarCellularSignalView
- (void)layoutSubviews {
    %orig;
    ASBSignalLayout(self);
}
%end

%hook STUIStatusBarCellularSignalView
- (void)layoutSubviews {
    %orig;
    ASBSignalLayout(self);
}
%end

#pragma mark - WiFi: 弧形 + 中心点 (双套类)

%hook _UIStatusBarWifiSignalView
- (void)layoutSubviews {
    %orig;
    ASBWifiLayout(self);
}
%end

%hook STUIStatusBarWifiSignalView
- (void)layoutSubviews {
    %orig;
    ASBWifiLayout(self);
}
%end

#pragma mark - 电池: 线性竖条 (iOS16 _UIBatteryView / iOS17 STUIStatusBarStaticBatteryView)

%hook _UIBatteryView
- (void)layoutSubviews {
    %orig;
    ASBBatteryLayout(self);
}
%end

%hook _UIStaticBatteryView
- (void)layoutSubviews {
    %orig;
    ASBBatteryLayout(self);
}
%end

%hook STUIStatusBarStaticBatteryView
- (void)layoutSubviews {
    %orig;
    ASBBatteryLayout(self);
}
%end

#pragma mark - ForegroundView 布局完成兜底 (iOS 17 布局走 setApplyingLayout:)

// 递归标记整棵子视图树需要重新布局, 确保数据更新后图标刷出新值
static void ASBRefreshSubtree(UIView *root) {
    for (UIView *sub in root.subviews) {
        [sub setNeedsLayout];
        ASBRefreshSubtree(sub);
    }
}

%hook _UIStatusBarForegroundView
- (void)setApplyingLayout:(BOOL)applying {
    %orig;
    if (!applying) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ASBRefreshSubtree(self);
        });
    }
}
%end

%hook STUIStatusBarForegroundView
- (void)setApplyingLayout:(BOOL)applying {
    %orig;
    if (!applying) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ASBRefreshSubtree(self);
        });
    }
}
%end

#pragma mark - 启动动画 (仅 SpringBoard)

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (gSigView && gWifiView && gBatView) {
            [ASBAnimator playIntroOnSignal:gSigView wifi:gWifiView battery:gBatView];
        }
    });
}
%end

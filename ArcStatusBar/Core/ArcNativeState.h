#import <UIKit/UIKit.h>

// 核心状态 + 原位绘制视图 (复刻参考插件 CANativeStatusState 机制):
//   - 收集真实数据 (信号格数/电池百分比/充电状态)
//   - 用 frame setter 记录的原始图标位置定位
//   - 隐藏原生图标, 在 ForegroundView 原位置用 CGContext 重绘极简图形
@interface ArcNativeState : UIView

+ (instancetype)sharedState;

// 真实数据
@property(nonatomic, assign) NSInteger activeBars;      // 信号格数 0~4
@property(nonatomic, assign) NSInteger chargePercent;   // 电量 0~100
@property(nonatomic, assign) BOOL charging;             // 充电中

// 原生图标位置记录 (由 frame setter hook 写入, drawRect 用它定位)
@property(nonatomic, weak) UIView *signalView;
@property(nonatomic, assign) CGRect signalFrame;
@property(nonatomic, weak) UIView *wifiView;
@property(nonatomic, assign) CGRect wifiFrame;
@property(nonatomic, weak) UIView *batteryView;
@property(nonatomic, assign) CGRect batteryFrame;

// 挂载到 ForegroundView (原位替换)
- (void)attachToHost:(UIView *)host;

@end

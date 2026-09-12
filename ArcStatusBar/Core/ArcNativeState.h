#import <UIKit/UIKit.h>

// 核心状态 + 原位绘制视图 (复刻参考插件 CANativeStatusState 机制):
//   - 收集真实数据 (信号格数/电池百分比/充电状态)
//   - 隐藏原生图标, 在 ForegroundView 原位置用 CGContext 重绘极简图形
@interface ArcNativeState : UIView

+ (instancetype)sharedState;

// 信号强度 (0~4) -> 4 点中点亮数量
@property(nonatomic, assign) NSInteger activeBars;
// 电池百分比 (0~100)
@property(nonatomic, assign) NSInteger chargePercent;
// 是否充电中
@property(nonatomic, assign) BOOL charging;
// WiFi/5G 数据更新标记 (仅用于触发重绘)
@property(nonatomic, assign) BOOL networkUpdated;

// 挂载到 ForegroundView (原位替换)
- (void)attachToHost:(UIView *)host;

@end

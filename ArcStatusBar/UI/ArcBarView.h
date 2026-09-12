#import <UIKit/UIKit.h>

// 贴原生状态栏右侧位置的极简点阵视图:
//   最右: 电池竖线 | 中间: 信号4点 | 左侧: WiFi 弧形+中心点
// 覆盖在原生电池/信号/WiFi 图标上, 视觉上等同替换
@interface ArcBarView : UIView
@property(nonatomic, assign, getter=isActive) BOOL active;
- (void)setActive:(BOOL)active animated:(BOOL)animated;
@end

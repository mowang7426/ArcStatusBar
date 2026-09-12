#import "ArcBarView.h"
#import <QuartzCore/QuartzCore.h>

// 参考视频的目标形态:
//   - 信号: 4 个白色圆点 (蜂窝信号位置)
//   - WiFi: 开口朝下的白色弧形 + 中心小点 (5G/WiFi 位置)
//   - 电池: 白色细竖线 (电池位置, 最右)
// 全部右对齐贴在原生图标上方, 背景透明, 视觉上=替换原生图标

@interface ArcBarView ()
@property(nonatomic, strong) NSMutableArray<CAShapeLayer *> *signalDots;
@property(nonatomic, strong) CAShapeLayer *wifiLayer;
@property(nonatomic, strong) CAShapeLayer *wifiDot;
@property(nonatomic, strong) CAShapeLayer *batteryLine;
@end

@implementation ArcBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = UIColor.clearColor;
    self.userInteractionEnabled = NO;

    // 信号 4 点
    _signalDots = [NSMutableArray array];
    for (NSInteger i = 0; i < 4; i++) {
        CAShapeLayer *dot = [CAShapeLayer layer];
        dot.fillColor = UIColor.whiteColor.CGColor;
        [self.layer addSublayer:dot];
        [_signalDots addObject:dot];
    }

    // WiFi 弧形 (开口朝下, 三弧 + 中心点)
    _wifiLayer = [CAShapeLayer layer];
    _wifiLayer.fillColor = UIColor.clearColor.CGColor;
    _wifiLayer.strokeColor = UIColor.whiteColor.CGColor;
    _wifiLayer.lineWidth = 2.0;
    _wifiLayer.lineCap = kCALineCapRound;
    [self.layer addSublayer:_wifiLayer];

    _wifiDot = [CAShapeLayer layer];
    _wifiDot.fillColor = UIColor.whiteColor.CGColor;
    [self.layer addSublayer:_wifiDot];

    // 电池竖线
    _batteryLine = [CAShapeLayer layer];
    _batteryLine.fillColor = UIColor.clearColor.CGColor;
    _batteryLine.strokeColor = UIColor.whiteColor.CGColor;
    _batteryLine.lineWidth = 2.2;
    _batteryLine.lineCap = kCALineCapRound;
    [self.layer addSublayer:_batteryLine];

    [self rebuildPaths];

    // 初始隐藏, 由 controller 启动时淡入
    self.layer.opacity = 0.0;
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self rebuildPaths];
}

- (void)rebuildPaths {
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat cy = h * 0.5;

    // 电池竖线: 最右
    CGFloat bx = w - 24.0;
    UIBezierPath *line = [UIBezierPath bezierPath];
    [line moveToPoint:CGPointMake(bx, cy - 7.0)];
    [line addLineToPoint:CGPointMake(bx, cy + 7.0)];
    self.batteryLine.path = line.CGPath;

    // 信号 4 点: 电池左侧
    CGFloat dotD = 4.0;
    CGFloat spacing = 8.5;
    for (NSInteger i = 0; i < 4; i++) {
        CGFloat dx = w - 62.0 + i * spacing;
        self.signalDots[i].path =
            [UIBezierPath bezierPathWithOvalInRect:
                CGRectMake(dx, cy - dotD * 0.5, dotD, dotD)].CGPath;
    }

    // WiFi 弧形: 信号左侧
    CGFloat wx = w - 108.0;
    UIBezierPath *arc = [UIBezierPath bezierPath];
    for (NSNumber *rv in @[@7.5, @5.0, @2.6]) {
        CGFloat r = rv.doubleValue;
        [arc addArcWithCenter:CGPointMake(wx, cy + 1.0)
                       radius:r
                   startAngle:(CGFloat)(M_PI * 1.18)
                     endAngle:(CGFloat)(M_PI * 1.82)
                    clockwise:YES];
    }
    self.wifiLayer.path = arc.CGPath;

    // WiFi 中心点
    self.wifiDot.path =
        [UIBezierPath bezierPathWithOvalInRect:
            CGRectMake(wx - 1.4, cy + 1.0 - 1.4, 2.8, 2.8)].CGPath;
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
    _active = active;

    void (^animations)(void) = ^{
        // active: 完全显示; 非 active: 略微收缩并半透明 (形变起点)
        self.layer.opacity = active ? 1.0 : 0.0;
        self.layer.transform = active
            ? CGAffineTransformIdentity
            : CGAffineTransformMakeScale(0.75, 0.75);
    };

    if (!animated) {
        animations();
        return;
    }

    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:animations
                     completion:nil];
}

@end

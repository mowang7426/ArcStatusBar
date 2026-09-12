#import "ArcNativeState.h"
#import <math.h>

@implementation ArcNativeState

+ (instancetype)sharedState {
    static ArcNativeState *state;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        state = [[ArcNativeState alloc] initWithFrame:CGRectZero];
        state.backgroundColor = UIColor.clearColor;
        state.userInteractionEnabled = NO;
        state.contentMode = UIViewContentModeRedraw;
    });
    return state;
}

#pragma mark - 数据 (变更即重绘)

- (void)setActiveBars:(NSInteger)activeBars {
    if (_activeBars != activeBars) {
        _activeBars = activeBars;
        [self setNeedsDisplay];
    }
}

- (void)setChargePercent:(NSInteger)chargePercent {
    if (_chargePercent != chargePercent) {
        _chargePercent = chargePercent;
        [self setNeedsDisplay];
    }
}

- (void)setCharging:(BOOL)charging {
    if (_charging != charging) {
        _charging = charging;
        [self setNeedsDisplay];
    }
}

#pragma mark - 位置记录 (由 frame setter hook 写入)

- (void)setSignalFrame:(CGRect)signalFrame {
    _signalFrame = signalFrame;
    [self setNeedsDisplay];
}

- (void)setWifiFrame:(CGRect)wifiFrame {
    _wifiFrame = wifiFrame;
    [self setNeedsDisplay];
}

- (void)setBatteryFrame:(CGRect)batteryFrame {
    _batteryFrame = batteryFrame;
    [self setNeedsDisplay];
}

#pragma mark - 挂载

- (void)attachToHost:(UIView *)host {
    if (!host) return;
    if (self.superview == host) {
        self.frame = host.bounds;
        return;
    }
    self.frame = host.bounds;
    [host addSubview:self];
}

#pragma mark - 原位绘制 (CGContext)

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIView *host = self.superview;
    if (!ctx || !host) return;

    // 优先用 frame setter 记录的精确位置; 未记录时回退到视图树转换
    CGRect sf = [self resolvedFrameForView:self.signalView cached:self.signalFrame host:host];
    CGRect wf = [self resolvedFrameForView:self.wifiView cached:self.wifiFrame host:host];
    CGRect bf = [self resolvedFrameForView:self.batteryView cached:self.batteryFrame host:host];

    if (!CGRectIsEmpty(sf) && !CGRectIsNull(sf)) [self drawSignalDots:ctx frame:sf];
    if (!CGRectIsEmpty(wf) && !CGRectIsNull(wf)) [self drawWifiArc:ctx frame:wf];
    if (!CGRectIsEmpty(bf) && !CGRectIsNull(bf)) [self drawBattery:ctx frame:bf];
}

- (CGRect)resolvedFrameForView:(UIView *)view cached:(CGRect)cached host:(UIView *)host {
    if (view && view.superview) {
        CGRect f = [host convertRect:view.bounds fromView:view];
        if (!CGRectIsNull(f) && !CGRectIsEmpty(f)) return f;
    }
    return cached;
}

// 信号: 4 个白点, 点亮数量 = activeBars
- (void)drawSignalDots:(CGContextRef)ctx frame:(CGRect)f {
    CGFloat d = 3.4;
    CGFloat spacing = 6.5;
    CGFloat cx = CGRectGetMinX(f) + d * 0.5;
    CGFloat cy = CGRectGetMidY(f);

    for (NSInteger i = 0; i < 4; i++) {
        if (i < self.activeBars) {
            CGContextSetFillColorWithColor(ctx, UIColor.whiteColor.CGColor);
        } else {
            CGContextSetFillColorWithColor(ctx,
                [UIColor.whiteColor colorWithAlphaComponent:0.22].CGColor);
        }
        CGContextFillEllipseInRect(ctx,
            CGRectMake(cx + i * spacing - d * 0.5, cy - d * 0.5, d, d));
    }
}

// WiFi: 开口朝下的三弧 + 中心点
- (void)drawWifiArc:(CGContextRef)ctx frame:(CGRect)f {
    CGContextSetStrokeColorWithColor(ctx, UIColor.whiteColor.CGColor);
    CGContextSetLineWidth(ctx, 1.7);
    CGContextSetLineCap(ctx, kCGLineCapRound);

    CGPoint c = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f) + 1.0);

    for (NSNumber *rv in @[@7.0, @4.6, @2.4]) {
        CGFloat r = rv.doubleValue;
        CGContextAddArc(ctx, c.x, c.y, r,
                        (CGFloat)(M_PI * 1.18), (CGFloat)(M_PI * 1.82), 0);
        CGContextStrokePath(ctx);
    }

    // 中心点
    CGContextSetFillColorWithColor(ctx, UIColor.whiteColor.CGColor);
    CGContextFillEllipseInRect(ctx,
        CGRectMake(c.x - 1.2, c.y - 1.2, 2.4, 2.4));
}

// 电池: 细竖线外框 + 内部填充 (高度 = chargePercent)
- (void)drawBattery:(CGContextRef)ctx frame:(CGRect)f {
    CGFloat cx = CGRectGetMidX(f);
    CGFloat top = CGRectGetMinY(f) + 2.0;
    CGFloat bottom = CGRectGetMaxY(f) - 2.0;
    CGFloat h = bottom - top;
    if (h <= 0) return;

    // 外框细竖线
    CGContextSetStrokeColorWithColor(ctx, UIColor.whiteColor.CGColor);
    CGContextSetLineWidth(ctx, 1.8);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextMoveToPoint(ctx, cx, top);
    CGContextAddLineToPoint(ctx, cx, bottom);
    CGContextStrokePath(ctx);

    // 内部填充 (从底部往上, 高度按百分比)
    CGFloat fill = h * (self.chargePercent / 100.0);
    if (fill > 1.0) {
        CGContextSetFillColorWithColor(ctx,
            self.charging
                ? [UIColor colorWithRed:0.25 green:0.85 blue:0.45 alpha:1.0].CGColor
                : UIColor.whiteColor.CGColor);
        CGContextFillRect(ctx, CGRectMake(cx - 0.8, bottom - fill, 1.6, fill));
    }
}

@end

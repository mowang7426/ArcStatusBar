#import "ArcNativeState.h"
#import <math.h>

// 递归收集宿主树中所有原生图标视图 (信号/WiFi/电池/5G 可能在深层子视图)
static void ASB_CollectTargets(UIView *root, NSMutableArray<UIView *> *outArr) {
    for (UIView *v in root.subviews) {
        NSString *cls = NSStringFromClass(v.class);
        if ([cls containsString:@"Signal"] ||
            [cls containsString:@"Wifi"] ||
            [cls containsString:@"WiFi"] ||
            [cls containsString:@"Battery"] ||
            [cls containsString:@"NetworkType"]) {
            [outArr addObject:v];
        }
        ASB_CollectTargets(v, outArr);
    }
}

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

#pragma mark - 数据

- (void)setActiveBars:(NSInteger)activeBars {
    _activeBars = activeBars;
    [self setNeedsDisplay];
}

- (void)setChargePercent:(NSInteger)chargePercent {
    _chargePercent = chargePercent;
    [self setNeedsDisplay];
}

- (void)setCharging:(BOOL)charging {
    _charging = charging;
    [self setNeedsDisplay];
}

- (void)setNetworkUpdated:(BOOL)networkUpdated {
    _networkUpdated = networkUpdated;
    [self setNeedsDisplay];
}

#pragma mark - 挂载

- (void)attachToHost:(UIView *)host {
    if (self.superview == host) {
        self.frame = host.bounds;
        return;
    }
    self.frame = host.bounds;
    [host addSubview:self];
}

#pragma mark - 绘制 (CGContext, 原位)

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIView *host = self.superview;
    if (!ctx || !host) return;

    // 递归收集原生图标视图 (已隐藏, 仅用其 frame 定位), 按类名绘制
    NSMutableArray<UIView *> *targets = [NSMutableArray array];
    ASB_CollectTargets(host, targets);

    for (UIView *v in targets) {
        if (v == self) continue;
        NSString *cls = NSStringFromClass(v.class);
        CGRect f = [host convertRect:v.bounds fromView:v];
        if (CGRectIsNull(f) || CGRectIsEmpty(f)) continue;

        if ([cls containsString:@"Signal"]) {
            [self drawSignalDots:ctx frame:f];
        } else if ([cls containsString:@"Wifi"] || [cls containsString:@"WiFi"]) {
            [self drawWifiArc:ctx frame:f];
        } else if ([cls containsString:@"Battery"]) {
            [self drawBattery:ctx frame:f];
        }
    }
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

#import "ArcMorphView.h"
#import <QuartzCore/QuartzCore.h>

@interface ArcMorphView ()
@property (nonatomic, strong) CAShapeLayer *arcLayer;
@property (nonatomic, strong) CAShapeLayer *wifiLayer;
@property (nonatomic, strong) NSMutableArray<CAShapeLayer *> *signalDots;
@property (nonatomic, strong) CAShapeLayer *batteryCapsule;
@property (nonatomic, strong) CAShapeLayer *batteryLine;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval animationStart;
@property (nonatomic, assign) BOOL reversing;
@end

@implementation ArcMorphView

static inline CGFloat ASClamp(CGFloat x, CGFloat a, CGFloat b) {
    return MAX(a, MIN(b, x));
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = UIColor.clearColor;
    self.userInteractionEnabled = NO;

    _arcLayer = [CAShapeLayer layer];
    _arcLayer.fillColor = UIColor.clearColor.CGColor;
    _arcLayer.strokeColor = UIColor.whiteColor.CGColor;
    _arcLayer.lineWidth = 2.8;
    _arcLayer.lineCap = kCALineCapRound;
    _arcLayer.strokeEnd = 0.0;
    [self.layer addSublayer:_arcLayer];

    _wifiLayer = [CAShapeLayer layer];
    _wifiLayer.fillColor = UIColor.clearColor.CGColor;
    _wifiLayer.strokeColor = UIColor.whiteColor.CGColor;
    _wifiLayer.lineWidth = 2.1;
    _wifiLayer.lineCap = kCALineCapRound;
    [self.layer addSublayer:_wifiLayer];

    _signalDots = [NSMutableArray array];
    for (NSInteger i = 0; i < 4; i++) {
        CAShapeLayer *dot = [CAShapeLayer layer];
        dot.fillColor = UIColor.whiteColor.CGColor;
        dot.opacity = 1.0;
        [self.layer addSublayer:dot];
        [_signalDots addObject:dot];
    }

    _batteryCapsule = [CAShapeLayer layer];
    _batteryCapsule.fillColor = UIColor.clearColor.CGColor;
    _batteryCapsule.strokeColor = UIColor.whiteColor.CGColor;
    _batteryCapsule.lineWidth = 1.8;
    [self.layer addSublayer:_batteryCapsule];

    _batteryLine = [CAShapeLayer layer];
    _batteryLine.fillColor = UIColor.clearColor.CGColor;
    _batteryLine.strokeColor = UIColor.whiteColor.CGColor;
    _batteryLine.lineWidth = 2.0;
    _batteryLine.lineCap = kCALineCapRound;
    _batteryLine.opacity = 0.0;
    [self.layer addSublayer:_batteryLine];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self rebuildPathsForProgress:self.morphActive ? 1.0 : 0.0];
}

- (UIBezierPath *)wifiPathWithProgress:(CGFloat)p {
    CGRect r = self.bounds;
    CGPoint c = CGPointMake(CGRectGetMidX(r) - 3.0, CGRectGetMidY(r) + 1.0);
    CGFloat s = 1.0;

    UIBezierPath *path = [UIBezierPath bezierPath];

    // Three Wi-Fi arcs remain visible throughout the morph.
    CGFloat outerR = 13.0 * s;
    CGFloat midR = 8.5 * s;
    CGFloat innerR = 4.2 * s;

    [path addArcWithCenter:c radius:outerR startAngle:(CGFloat)(M_PI * 1.18)
                  endAngle:(CGFloat)(M_PI * 1.82) clockwise:YES];
    [path addArcWithCenter:c radius:midR startAngle:(CGFloat)(M_PI * 1.18)
                  endAngle:(CGFloat)(M_PI * 1.82) clockwise:YES];
    [path addArcWithCenter:c radius:innerR startAngle:(CGFloat)(M_PI * 1.18)
                  endAngle:(CGFloat)(M_PI * 1.82) clockwise:YES];

    CGFloat dotR = 1.6;
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:
                      CGRectMake(c.x - dotR, c.y + 1.0, dotR * 2, dotR * 2)]];
    return path;
}

- (UIBezierPath *)arcPath {
    CGRect r = self.bounds;
    CGPoint c = CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r) + 2.0);
    CGFloat radius = MIN(CGRectGetWidth(r), CGRectGetHeight(r)) * 0.46;

    UIBezierPath *p = [UIBezierPath bezierPath];
    // Start on the right and grow counter-clockwise into the upper ring.
    [p addArcWithCenter:c
                 radius:radius
             startAngle:(CGFloat)(-0.16 * M_PI)
               endAngle:(CGFloat)(1.16 * M_PI)
              clockwise:YES];
    return p;
}

- (void)rebuildPathsForProgress:(CGFloat)p {
    p = ASClamp(p, 0.0, 1.0);

    CGRect r = self.bounds;
    CGFloat cy = CGRectGetMidY(r);
    CGFloat left = 18.0;
    CGFloat spacing = 8.0;

    // Cellular bars morph into four small dots underneath Wi-Fi.
    for (NSInteger i = 0; i < 4; i++) {
        CGFloat barH = 5.0 + i * 3.0;
        CGFloat barX = left + i * 7.0;
        CGFloat barY = cy - barH * 0.5;

        CGFloat dotX = CGRectGetMidX(r) - 12.0 + i * spacing;
        CGFloat dotY = cy + 16.0;

        CGFloat x = barX + (dotX - barX) * p;
        CGFloat y = barY + (dotY - barY) * p;
        CGFloat w0 = 4.0;
        CGFloat h0 = barH;
        CGFloat size = 3.2;
        CGFloat w = w0 + (size - w0) * p;
        CGFloat h = h0 + (size - h0) * p;

        self.signalDots[i].path =
            [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h)
                                       cornerRadius:MIN(w, h) * 0.5].CGPath;
    }

    // Battery capsule morphs to a vertical line on the far right.
    CGFloat bx = CGRectGetMaxX(r) - 27.0;
    CGFloat by = cy - 8.0;
    CGFloat bw = 22.0;
    CGFloat bh = 16.0;

    self.batteryCapsule.path =
        [UIBezierPath bezierPathWithRoundedRect:CGRectMake(bx, by, bw, bh)
                                   cornerRadius:bh * 0.5].CGPath;
    self.batteryCapsule.opacity = 1.0 - p;

    CGFloat lx = bx + bw * 0.5;
    UIBezierPath *line = [UIBezierPath bezierPath];
    [line moveToPoint:CGPointMake(lx, cy - 8.0)];
    [line addLineToPoint:CGPointMake(lx, cy + 8.0)];
    self.batteryLine.path = line.CGPath;
    self.batteryLine.opacity = p;

    self.wifiLayer.path = [self wifiPathWithProgress:p].CGPath;
    self.arcLayer.path = [self arcPath].CGPath;
    self.arcLayer.strokeEnd = p;

    // Arc is intentionally slightly translucent during the initial movement.
    self.arcLayer.opacity = p;
}

- (void)setMorphActive:(BOOL)active animated:(BOOL)animated {
    _morphActive = active;

    [self.displayLink invalidate];
    self.displayLink = nil;

    if (!animated) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self rebuildPathsForProgress:active ? 1.0 : 0.0];
        [CATransaction commit];
        return;
    }

    self.reversing = !active;
    self.animationStart = CACurrentMediaTime();

    self.displayLink = [CADisplayLink displayLinkWithTarget:self
                                                   selector:@selector(stepAnimation:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)playForward {
    [self setMorphActive:YES animated:YES];
}

- (void)playReverse {
    [self setMorphActive:NO animated:YES];
}

- (void)stepAnimation:(CADisplayLink *)link {
    CGFloat duration = 0.62;
    CGFloat t = (CACurrentMediaTime() - self.animationStart) / duration;
    t = ASClamp(t, 0.0, 1.0);

    // Smooth ease-in-out, close to the reference video's organic morph.
    CGFloat e = t * t * (3.0 - 2.0 * t);
    CGFloat p = self.reversing ? (1.0 - e) : e;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self rebuildPathsForProgress:p];
    [CATransaction commit];

    if (t >= 1.0) {
        [link invalidate];
        self.displayLink = nil;
    }
}

@end

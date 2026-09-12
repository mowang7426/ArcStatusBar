#import "ArcMorphView.h"

@interface ArcMorphView ()
@property(nonatomic, strong) CAShapeLayer *arcLayer;
@property(nonatomic, strong) NSMutableArray<UIView *> *topDots;
@property(nonatomic, strong) NSMutableArray<UIView *> *bottomDots;
@property(nonatomic, strong) UILabel *centerLabel;
@end

@implementation ArcMorphView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;

        _topDots = [NSMutableArray array];
        _bottomDots = [NSMutableArray array];

        _centerLabel = [[UILabel alloc] init];
        _centerLabel.text = @"WiFi";
        _centerLabel.textAlignment = NSTextAlignmentCenter;
        _centerLabel.textColor = UIColor.whiteColor;
        _centerLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        [self addSubview:_centerLabel];

        for (NSInteger i = 0; i < 4; i++) {
            UIView *top = [self dot];
            UIView *bottom = [self dot];

            [_topDots addObject:top];
            [_bottomDots addObject:bottom];

            [self addSubview:top];
            [self addSubview:bottom];
        }

        _arcLayer = [CAShapeLayer layer];
        _arcLayer.fillColor = UIColor.clearColor.CGColor;
        _arcLayer.strokeColor =
            [UIColor colorWithRed:0.12 green:0.86 blue:0.31 alpha:1.0].CGColor;
        _arcLayer.lineWidth = 7.0;
        _arcLayer.lineCap = kCALineCapRound;
        _arcLayer.strokeStart = 0.0;
        _arcLayer.strokeEnd = 0.0;

        [self.layer addSublayer:_arcLayer];
    }
    return self;
}

- (UIView *)dot {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 6, 6)];
    v.backgroundColor = UIColor.whiteColor;
    v.layer.cornerRadius = 3.0;
    v.alpha = 0.85;
    return v;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGPoint c = CGPointMake(w / 2.0, h / 2.0);

    _centerLabel.frame = CGRectMake(c.x - 35, c.y - 12, 70, 24);

    UIBezierPath *path =
        [UIBezierPath bezierPathWithArcCenter:c
                                      radius:30.0
                                  startAngle:(CGFloat)(M_PI * 1.12)
                                    endAngle:(CGFloat)(M_PI * 1.88)
                                   clockwise:YES];

    _arcLayer.frame = self.bounds;
    _arcLayer.path = path.CGPath;

    for (NSInteger i = 0; i < 4; i++) {
        UIView *top = _topDots[i];
        UIView *bottom = _bottomDots[i];

        top.center = CGPointMake(c.x - 18 + i * 12, c.y - 37);
        bottom.center = CGPointMake(c.x - 18 + i * 12, c.y + 37);
    }
}

- (void)setArcMode:(BOOL)arcMode animated:(BOOL)animated {
    _arcMode = arcMode;

    void (^animations)(void) = ^{
        self.arcLayer.strokeEnd = arcMode ? 0.78 : 0.0;

        CGFloat scale = arcMode ? 1.0 : 0.82;
        self.centerLabel.transform = CGAffineTransformMakeScale(scale, scale);

        for (UIView *v in self.topDots) {
            v.transform = arcMode
                ? CGAffineTransformMakeScale(1.12, 1.12)
                : CGAffineTransformIdentity;
            v.alpha = arcMode ? 1.0 : 0.45;
        }

        for (UIView *v in self.bottomDots) {
            v.transform = arcMode
                ? CGAffineTransformMakeScale(1.08, 1.08)
                : CGAffineTransformIdentity;
            v.alpha = arcMode ? 1.0 : 0.35;
        }
    };

    if (!animated) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        animations();
        [CATransaction commit];
        return;
    }

    [UIView animateWithDuration:0.48
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:nil];

    if (arcMode) {
        CABasicAnimation *pulse =
            [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pulse.fromValue = @0.58;
        pulse.toValue = @0.84;
        pulse.duration = 0.95;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        pulse.timingFunction =
            [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        [self.arcLayer addAnimation:pulse forKey:@"ArcPulse"];
    } else {
        [self.arcLayer removeAnimationForKey:@"ArcPulse"];
    }
}

@end

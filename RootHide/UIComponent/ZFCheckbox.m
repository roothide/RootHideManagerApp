//
//  ZFCheckbox.m
//  ZFCheckbox
//
//  Created by Amornchai Kanokpullwad on 30/03/2015.
//
//

#import "ZFCheckbox.h"

CGFloat const kLine1UnselectedStart = 0.2;
CGFloat const kLine1UnselectedEnd = 1.0;
CGFloat const kLine1SelectedStart = 0.0;
CGFloat const kLine1SelectedEnd = 0.08;

CGFloat const kLine2UnselectedStart = 0.41;
CGFloat const kLine2UnselectedEnd = 1.0;
CGFloat const kLine2SelectedStart = 0.0;
CGFloat const kLine2SelectedEnd = 0.28;

@interface ZFCheckbox ()
@property (nonatomic, strong) CAShapeLayer *line1Layer;
@property (nonatomic, strong) CAShapeLayer *line2Layer;
@end

@implementation ZFCheckbox

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    // default
    self.lineWidth = 1.5;
    self.lineColor = [UIColor systemBlueColor];
    self.lineBackgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];
    self.animateDuration = 0.3;
    
    self.line1Layer = [CAShapeLayer layer];
    self.line2Layer = [CAShapeLayer layer];
    
    [self.layer addSublayer:self.line1Layer];
    [self.layer addSublayer:self.line2Layer];
}

- (void)drawRect:(CGRect)rect
{
    CGRect insetRect = CGRectInset(rect, self.lineWidth, self.lineWidth);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:insetRect];
    path.lineWidth = self.lineWidth;
    [self.lineBackgroundColor setStroke];
    [path stroke];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.line1Layer.strokeColor = self.line2Layer.strokeColor = self.lineColor.CGColor;
    self.line1Layer.fillColor = self.line2Layer.fillColor = [UIColor clearColor].CGColor;
    self.line1Layer.lineCap = self.line2Layer.lineCap = kCALineCapRound;
    self.line1Layer.lineJoin = self.line2Layer.lineJoin = kCALineJoinRound;
    self.line1Layer.lineWidth = self.line2Layer.lineWidth = self.lineWidth;
    
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGRect insetRect = CGRectInset(self.bounds, self.lineWidth, self.lineWidth);
    CGFloat radius = (CGRectGetWidth(insetRect) > CGRectGetHeight(insetRect) ? CGRectGetHeight(insetRect) : CGRectGetWidth(insetRect)) / 2.0;
    CGPoint startPoint = CGPointMake(center.x - 0.25 * radius, center.y + 0.45 * radius);
    
    CGFloat angle1 = 13 * M_PI/12;
    CGFloat angle2 = 9 * M_PI/5;
    
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:startPoint];
    [path1 addArcWithCenter:center radius:radius startAngle:angle1 endAngle:angle2 clockwise:NO];
    
    UIBezierPath *path2 = [UIBezierPath bezierPath];
    [path2 moveToPoint:startPoint];
    [path2 addArcWithCenter:center radius:radius startAngle:angle2 endAngle:angle1 clockwise:NO];
    
    self.line1Layer.path = path1.CGPath;
    self.line2Layer.path = path2.CGPath;
    
    [self setSelected:self.selected animated:NO];
}

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected];
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:animated ? self.animateDuration : 0];
    
    if (self.selected) {
        self.line1Layer.strokeStart = kLine1SelectedStart;
        self.line1Layer.strokeEnd = kLine1SelectedEnd;
        self.line2Layer.strokeStart = kLine2SelectedStart;
        self.line2Layer.strokeEnd = kLine2SelectedEnd;
    } else {
        self.line1Layer.strokeStart = kLine1UnselectedStart;
        self.line1Layer.strokeEnd = kLine1UnselectedEnd;
        self.line2Layer.strokeStart = kLine2UnselectedStart;
        self.line2Layer.strokeEnd = kLine2UnselectedEnd;
    }
    
    [CATransaction commit];

}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    if (CGRectContainsPoint(self.bounds,[touch locationInView:self]))
    {
        [self setSelected:!self.selected animated:YES];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

@end

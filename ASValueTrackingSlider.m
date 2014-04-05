//
//  ASValueTrackingSlider.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ASValueTrackingSlider.h"

#define ARROW_LENGTH 6

@interface ASValuePopUpView : UIView
- (void)setString:(NSAttributedString *)string;
- (UIColor *)popUpViewColor;
- (void)setPopUpViewColor:(UIColor *)color;
- (void)setPopUpViewAnimatedColors:(NSArray *)animatedColors offset:(CGFloat)offset;
- (void)setAnimationOffset:(CGFloat)offset;
@end

@implementation ASValuePopUpView
{
    CAShapeLayer *_backgroundLayer;
    CATextLayer *_textLayer;
    CGSize _oldSize;
    CGFloat _arrowCenterOffset;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.anchorPoint = CGPointMake(0.5, 1);

        self.userInteractionEnabled = NO;
        _backgroundLayer = [CAShapeLayer layer];
        _backgroundLayer.anchorPoint = CGPointMake(0, 0);
        
        _textLayer = [CATextLayer layer];
        _textLayer.alignmentMode = kCAAlignmentCenter;
        _textLayer.anchorPoint = CGPointMake(0, 0);
        _textLayer.contentsScale = [UIScreen mainScreen].scale;
        _textLayer.actions = @{@"bounds" : [NSNull null],   // prevent implicit animation of bounds
                               @"position" : [NSNull null]};// and position

        [self.layer addSublayer:_backgroundLayer];
        [self.layer addSublayer:_textLayer];
    }
    return self;
}

- (void)setString:(NSAttributedString *)string
{
    _textLayer.string = string;
}

- (UIColor *)popUpViewColor
{
    return [UIColor colorWithCGColor:[_backgroundLayer.presentationLayer fillColor]];
}

- (void)setPopUpViewColor:(UIColor *)color;
{
    [_backgroundLayer removeAnimationForKey:@"fillColor"];
    _backgroundLayer.fillColor = color.CGColor;
}

- (void)setPopUpViewAnimatedColors:(NSArray *)animatedColors offset:(CGFloat)offset;
{
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *col in animatedColors) {
        [cgColors addObject:(id)col.CGColor];
    }
    
    CAKeyframeAnimation *colorAnim = [CAKeyframeAnimation animationWithKeyPath:@"fillColor"];
    colorAnim.values = cgColors;
    colorAnim.fillMode = kCAFillModeBoth;
    colorAnim.duration = 1.0;
    [_backgroundLayer addAnimation:colorAnim forKey:@"fillColor"];
    
    _backgroundLayer.speed = 0.0;
    _backgroundLayer.beginTime = offset;
    _backgroundLayer.timeOffset = 0.0;
}

- (void)setAnimationOffset:(CGFloat)offset
{
    _backgroundLayer.timeOffset = offset;
}

- (void)setArrowCenterOffset:(CGFloat)offset
{
    // only redraw if the offset has changed
    if (_arrowCenterOffset != offset) {
        _arrowCenterOffset = offset;
        
        // the arrow tip should be the origin of any scale animations
        // to achieve this, position the anchorPoint at the tip of the arrow
        self.layer.anchorPoint = CGPointMake(0.5+(offset/self.bounds.size.width), 1);
        [self drawPath];
    }
}

- (void)drawPath
{
    // Create rounded rect
    CGRect roundedRect = self.bounds;
    roundedRect.size.height -= ARROW_LENGTH;
    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:20.0];
    
    // Create arrow path
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    CGFloat arrowX = CGRectGetMidX(self.bounds) + _arrowCenterOffset;
    CGPoint p0 = CGPointMake(arrowX, CGRectGetMaxY(self.bounds));
    [arrowPath moveToPoint:p0];
    [arrowPath addLineToPoint:CGPointMake((arrowX - 6.0), CGRectGetMaxY(roundedRect))];
    [arrowPath addLineToPoint:CGPointMake((arrowX + 6.0), CGRectGetMaxY(roundedRect))];
    [arrowPath closePath];
    
    // combine arrow path and rounded rect
    [roundedRectPath appendPath:arrowPath];

    _backgroundLayer.path = roundedRectPath.CGPath;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // only redraw if the view size has changed
    if (!CGSizeEqualToSize(self.bounds.size, _oldSize)) {
        _oldSize = self.bounds.size;
        _backgroundLayer.bounds = self.bounds;

        CGFloat textHeight = [_textLayer.string size].height;
        CGRect textRect = CGRectMake(self.bounds.origin.x,
                                     (self.bounds.size.height-ARROW_LENGTH-textHeight)/2,
                                     self.bounds.size.width, textHeight);
        _textLayer.frame = textRect;
        [self drawPath];
    }
}

@end


@interface ASValueTrackingSlider()
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) ASValuePopUpView *popUpView;
@property (readonly, nonatomic) CGRect thumbRect;
@property (strong, nonatomic) NSMutableAttributedString *attributedString;
@property (nonatomic, assign) BOOL highlightedPrevious;

@property (nonatomic, strong) UIColor *thumbColorNormal;
@property (nonatomic, strong) UIColor *thumbColorHighlighted;
@property (nonatomic, assign) CGFloat thumbRadiusNormal;
@property (nonatomic, assign) CGFloat thumbRadiusHighlighted;

@end

#define MIN_POPUPVIEW_WIDTH 36.0
#define MIN_POPUPVIEW_HEIGHT 40.0
#define POPUPVIEW_WIDTH_INSET 30.0

@implementation ASValueTrackingSlider
{
    CGFloat _popUpViewWidth;
    CGFloat _popUpViewHeight;
    UIColor *_popUpViewColor;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - Additions

static NSString * const kSliderTrack = @"sliderTrackImage";
static NSString * const kSliderThumbName = @"sliderThumbName";


static const CGFloat kTouchZonePadding = 10.0;

#pragma mark Initialization

- (void)awakeFromNib
{
    [self setMaxFractionDigitsDisplayed:0];
    self.popUpViewColor = [UIColor colorWithRed:0.95 green:0.32 blue:0.21 alpha:1];
    self.textColor = [UIColor whiteColor];
    
    [self setNumberFormatter:[[NSNumberFormatter alloc] init]];
}

- (void)setThumbColorNormal:(UIColor *)thumbColorNormal
      thumbColorHighlighted:(UIColor *)thumbColorHighlighted
          thumbRadiusNormal:(CGFloat)thumbRadiusNormal
     thumbRadiusHighlighted:(CGFloat)thumbRadiusHighlighted
{
    self.thumbColorNormal = thumbColorNormal;
    self.thumbColorHighlighted = thumbColorHighlighted;
    self.thumbRadiusNormal = thumbRadiusNormal;
    self.thumbRadiusHighlighted = thumbRadiusHighlighted;
    
    [self setThumbImage:[self imageCircleWithRadius:thumbRadiusNormal color:thumbColorNormal]];
}

- (UIImage *)imageCircleWithRadius:(CGFloat)radius color:(UIColor *)color
{
    CGFloat diameter = radius * 2.0;
    CGRect rect = CGRectMake(0.0, 0.0, diameter, diameter);
    
    CGFloat colorRed;
    CGFloat colorGreen;
    CGFloat colorBlue;
    CGFloat colorAlpha;
    [color getRed:&colorRed green:&colorGreen blue:&colorBlue alpha:&colorAlpha];
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 2.0);
    
    CGFloat lineWidth = 2.0;
    CGRect borderRect = CGRectInset(rect, lineWidth * 0.5, lineWidth * 0.5);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, colorRed, colorGreen, colorBlue, colorAlpha);
    CGContextFillEllipseInRect (context, borderRect);
    CGContextFillPath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)replaceViewLayer:(UIView *)view withCircleRadius:(CGFloat)radius color:(UIColor *)color
{
    view.layer.contents = nil;
    view.layer.cornerRadius = radius;
    view.layer.backgroundColor = color.CGColor;
}

- (void)setThumbImage:(UIImage *)thumbImage
{
    [self setThumbImage:thumbImage forState:UIControlStateNormal & UIControlStateHighlighted];
}

#pragma mark Touch Reaction

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted && !self.highlightedPrevious)
    {
        UIView *view = [self findThumbView];
        [self replaceViewLayer:view withCircleRadius:self.thumbRadiusNormal color:self.thumbColorNormal];
        view.layer.name = kSliderThumbName;
        [self scaleUpView:view];
    }
    else if (!highlighted && self.highlightedPrevious)
    {
        [self scaleDownView:[self findThumbView]];
    }
    self.highlightedPrevious = highlighted;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, -kTouchZonePadding, -kTouchZonePadding);
    return CGRectContainsPoint(bounds, point);
}

#pragma mark Animation

- (UIView *)findThumbView
{
    CGSize currentImageSize = self.currentThumbImage.size;
    
    if (CGSizeEqualToSize(currentImageSize, CGSizeZero))
    {
        currentImageSize = CGSizeMake(31.0, 31.0);
    }
    UIView *thumbView = nil;
    
    for (UIView *view in self.subviews)
    {
        CGSize viewSize = view.bounds.size;
        
        if (CGSizeEqualToSize(currentImageSize, viewSize) || [view.layer.name isEqualToString:kSliderThumbName])
        {
            thumbView = view;
        }
    }
    return thumbView;
}

- (void)scaleUpView:(UIView *)view
{
    CGFloat transformationScale = self.thumbRadiusHighlighted / self.thumbRadiusNormal;
    
    if (view && self.withAnimation)
    {
        [CATransaction begin];
        
        CGFloat animationDuration = 0.2;
        
        NSValue *fromValue = [view.layer animationForKey:@"transform"] ?
        [view.layer.presentationLayer valueForKey:@"transform"] :
        [NSValue valueWithCATransform3D:CATransform3DIdentity];
        
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        scaleAnimation.fromValue = fromValue;
        scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(transformationScale, transformationScale, 1.0)];
        [scaleAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        scaleAnimation.removedOnCompletion = NO;
        scaleAnimation.fillMode = kCAFillModeForwards;
        scaleAnimation.duration = animationDuration;
        [view.layer addAnimation:scaleAnimation forKey:@"transform"];
        
        CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        colorAnimation.fromValue = (id)self.thumbColorNormal.CGColor;
        colorAnimation.toValue = (id)self.thumbColorHighlighted.CGColor;
        colorAnimation.duration = animationDuration;
        [view.layer addAnimation:colorAnimation forKey:@"backgroundColor"];
        
        [CATransaction commit];
    }
    else if (view)
    {
        view.layer.transform = CATransform3DMakeScale(transformationScale, transformationScale, 1.0);
    }
    view.layer.backgroundColor = self.thumbColorHighlighted.CGColor;
}

- (void)scaleDownView:(UIView *)view
{
    if (view && self.withAnimation)
    {
        [CATransaction begin];
        
        CGFloat animationDuration = 0.2;
        
        CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
        scaleAnim.fromValue = [view.layer.presentationLayer valueForKey:@"transform"];
        scaleAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        scaleAnim.duration = animationDuration;
        scaleAnim.removedOnCompletion = NO;
        scaleAnim.fillMode = kCAFillModeForwards;
        [scaleAnim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        [view.layer addAnimation:scaleAnim forKey:@"transform"];
        
        CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        colorAnimation.fromValue = (id)self.thumbColorHighlighted.CGColor;
        colorAnimation.toValue = (id)self.thumbColorNormal.CGColor;
        colorAnimation.duration = animationDuration;
        [view.layer addAnimation:colorAnimation forKey:@"backgroundColor"];
        
        [CATransaction commit];
    }
    else if (view)
    {
        view.layer.transform = CATransform3DIdentity;
    }
    view.layer.backgroundColor = self.thumbColorNormal.CGColor;
}

#pragma mark - public methods

- (void)setTextColor:(UIColor *)color
{
    _textColor = color;
    [self.attributedString addAttribute:NSForegroundColorAttributeName
                                  value:(id)color.CGColor
                                  range:NSMakeRange(0, [_attributedString length])];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    [self.attributedString addAttribute:NSFontAttributeName
                                  value:font
                                  range:NSMakeRange(0, [_attributedString length])];
    [self calculatePopUpViewSize];
}

// return the currently displayed color if possible, otherwise return _popUpViewColor
// if animated colors are set, the color will change each time the slider value changes
- (UIColor *)popUpViewColor
{
    return [self.popUpView popUpViewColor] ?: _popUpViewColor;
}

- (void)setPopUpViewColor:(UIColor *)popUpViewColor
{
    _popUpViewColor = popUpViewColor;
    [self.popUpView setPopUpViewColor:popUpViewColor];
}

// if only 1 color is present then call 'setPopUpViewColor:'
// if arg is nil then restore previous _popUpViewColor
// otherwise, set animated colors
- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors
{
    _popUpViewAnimatedColors = popUpViewAnimatedColors;
    
    if ([popUpViewAnimatedColors count] < 2) {
        [self.popUpView setPopUpViewColor:[popUpViewAnimatedColors lastObject] ?: _popUpViewColor];
    } else {
        [self.popUpView setPopUpViewAnimatedColors:popUpViewAnimatedColors
                                            offset:[self currentValueOffset]];
    }
}

// when either the min/max value or number formatter changes, recalculate the popUpView width
- (void)setMaximumValue:(float)maximumValue
{
    [super setMaximumValue:maximumValue];
    [self calculatePopUpViewSize];
}

- (void)setMinimumValue:(float)minimumValue
{
    [super setMinimumValue:minimumValue];
    [self calculatePopUpViewSize];
}

// set max and min digits to same value to keep string length consistent
- (void)setMaxFractionDigitsDisplayed:(NSUInteger)maxDigits;
{
    [self.numberFormatter setMaximumFractionDigits:maxDigits];
    [self.numberFormatter setMinimumFractionDigits:maxDigits];
    [self calculatePopUpViewSize];
}

- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    _numberFormatter = numberFormatter;
    [self calculatePopUpViewSize];
}

#pragma mark - private methods

- (void)setup
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    self.numberFormatter = formatter;
    [self setMaxFractionDigitsDisplayed:2];
    
    self.popUpView = [[ASValuePopUpView alloc] initWithFrame:CGRectZero];
    self.popUpView.alpha = self.withAnimation;
    [self addSubview:self.popUpView];
    
    self.attributedString = [[NSMutableAttributedString alloc] initWithString:@" " attributes:nil];
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont boldSystemFontOfSize:22.0f];
    self.popUpViewColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    
    [self calculatePopUpViewSize];
}

- (void)showPopUp
{
    if (self.withAnimation)
    {
        [CATransaction begin]; {
            // if the transfrom animation hasn't run yet then set a default fromValue
            NSValue *fromValue = [self.popUpView.layer animationForKey:@"transform"] ?
            [self.popUpView.layer.presentationLayer valueForKey:@"transform"] :
            [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 1)];
            
            CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
            scaleAnim.fromValue = fromValue;
            scaleAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
            [scaleAnim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            scaleAnim.removedOnCompletion = NO;
            scaleAnim.fillMode = kCAFillModeForwards;
            scaleAnim.duration = 0.1;
            [self.popUpView.layer addAnimation:scaleAnim forKey:@"transform"];
            
            CABasicAnimation* fadeInAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeInAnim.fromValue = [self.popUpView.layer.presentationLayer valueForKey:@"opacity"];
            fadeInAnim.duration = 0.1;
            fadeInAnim.toValue = @1.0;
            [self.popUpView.layer addAnimation:fadeInAnim forKey:@"opacity"];
        } [CATransaction commit];
    }
    self.popUpView.layer.opacity = 1.0;
}

- (void)hidePopUp
{
    if (self.withAnimation)
    {
        [CATransaction begin]; {
            CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
            scaleAnim.fromValue = [self.popUpView.layer.presentationLayer valueForKey:@"transform"];
            scaleAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 1)];
            scaleAnim.duration = 0.1;
            scaleAnim.removedOnCompletion = NO;
            scaleAnim.fillMode = kCAFillModeForwards;
            [scaleAnim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [self.popUpView.layer addAnimation:scaleAnim forKey:@"transform"];
            
            CABasicAnimation* fadeOutAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeOutAnim.fromValue = [self.popUpView.layer.presentationLayer valueForKey:@"opacity"];
            fadeOutAnim.toValue = @0.0;
            fadeOutAnim.duration = 0.1;
            [self.popUpView.layer addAnimation:fadeOutAnim forKey:@"opacity"];
        } [CATransaction commit];
    }
    self.popUpView.layer.opacity = 0.0;
}

- (void)positionAndUpdatePopUpView
{
    CGRect thumbRect = self.thumbRect;
    
    CGFloat thumbW = thumbRect.size.width;
    CGFloat thumbH = thumbRect.size.height;

    CGRect popUpRect = CGRectInset(thumbRect, (thumbW - _popUpViewWidth)/2, (thumbH -_popUpViewHeight)/2);
    const CGFloat popUpOffcet = 8.0;
    popUpRect.origin.y = thumbRect.origin.y - _popUpViewHeight - popUpOffcet;
    
    self.popUpView.frame = popUpRect;
    
    NSString *string = [_numberFormatter stringFromNumber:@(self.value)];
    [[self.attributedString mutableString] setString:string];
    [self.popUpView setString:self.attributedString];
    
    [self.popUpView setAnimationOffset:[self currentValueOffset]];
}

- (void)calculatePopUpViewSize
{
    // if the abs of minimumValue is the same or larger than maximumValue, use it to calculate size
    CGFloat value = ABS(self.minimumValue) >= self.maximumValue ? self.minimumValue : self.maximumValue;
    NSString *string = [_numberFormatter stringFromNumber:@(value)];
    [[self.attributedString mutableString] setString:string];
    _popUpViewWidth = ceilf(MAX([self.attributedString size].width, MIN_POPUPVIEW_WIDTH)+POPUPVIEW_WIDTH_INSET);
    _popUpViewHeight = ceilf(MAX([self.attributedString size].height, MIN_POPUPVIEW_HEIGHT)+ARROW_LENGTH);
    
    [self positionAndUpdatePopUpView];
}

- (CGRect)thumbRect
{
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                       trackRect:[self trackRectForBounds:self.bounds]
                                           value:self.value];
    
    CGFloat radiusDelta = -fabs(self.thumbRadiusHighlighted - self.thumbRadiusNormal);
    
    return CGRectInset(thumbRect, radiusDelta, radiusDelta);
}

// returns the current offset of UISlider value in the range 0.0 – 1.0
- (CGFloat)currentValueOffset
{
    CGFloat valueRange = self.maximumValue - self.minimumValue;
    return (self.value + ABS(self.minimumValue)) / valueRange;
}

#pragma mark - subclassed methods

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL begin = [super beginTrackingWithTouch:touch withEvent:event];
    if (begin) {
        [self positionAndUpdatePopUpView];
        [self showPopUp];
    }
    return begin;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL continueTrack = [super continueTrackingWithTouch:touch withEvent:event];
    if (continueTrack) [self positionAndUpdatePopUpView];
    return continueTrack;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [super cancelTrackingWithEvent:event];
    [self hidePopUp];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    [self positionAndUpdatePopUpView];
    [self hidePopUp];
}

@end

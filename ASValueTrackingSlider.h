//
//  ASValueTrackingSlider.h
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ASValueTrackingSlider : UISlider
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) UIFont *font;

// setting the value of 'popUpViewColor' overrides 'popUpViewAnimatedColors' and vice versa
// the return value of 'popUpViewColor' is the currently displayed value
// this will vary if 'popUpViewAnimatedColors' is set (see below)
@property (strong, nonatomic) UIColor *popUpViewColor;

// pass an array of  2 or more UIColors to animate the color change as the slider moves
@property (strong, nonatomic) NSArray *popUpViewAnimatedColors;

@property (nonatomic, assign) BOOL withAnimation;

- (void)setThumbColorNormal:(UIColor *)thumbColorNormal
      thumbColorHighlighted:(UIColor *)thumbColorHighlighted
          thumbRadiusNormal:(CGFloat)thumbRadiusNormal
     thumbRadiusHighlighted:(CGFloat)thumbRadiusHighlighted;

// when setting max FractionDigits the min value is automatically set to the same value
// this ensures that the PopUpView frame maintains a consistent width
- (void)setMaxFractionDigitsDisplayed:(NSUInteger)maxDigits;

// take full control of the format dispayed with a custom NSNumberFormatter
- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter;



@end

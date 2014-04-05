//
//  ASViewController.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ASViewController.h"
#import "ASValueTrackingSlider.h"

@interface ASViewController ()
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider1;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider2;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider3;
@end

@implementation ASViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // customize slider 1
    self.slider1.maximumValue = 2.0;
    self.slider1.withAnimation = YES;
    [self.slider1 setThumbColorNormal:[UIColor blackColor]
                thumbColorHighlighted:[UIColor redColor]
                    thumbRadiusNormal:17.0
               thumbRadiusHighlighted:35.0];
    
    // customize slider 2
    self.slider2.minimumValue = 1990.0;
    self.slider2.maximumValue = 2020.0;
    self.slider2.withAnimation = YES;
    [self.slider2 setThumbColorNormal:[UIColor blackColor]
                thumbColorHighlighted:[UIColor colorWithRed:0.95 green:0.32 blue:0.21 alpha:1]
                    thumbRadiusNormal:9.0
               thumbRadiusHighlighted:33.0];
    [self.slider2 setMaxFractionDigitsDisplayed:0];
    self.slider2.font = [UIFont fontWithName:@"ProximaNova-Bold" size:18];

    
    // customize slider 3
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterPercentStyle];
    [self.slider3 setNumberFormatter:formatter];
    self.slider3.withAnimation = YES;
    [self.slider3 setThumbColorNormal:[UIColor whiteColor]
                thumbColorHighlighted:[UIColor grayColor]
                    thumbRadiusNormal:15.0
               thumbRadiusHighlighted:30.0];
    self.slider3.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:26];
    self.slider3.popUpViewAnimatedColors = @[[UIColor purpleColor], [UIColor redColor], [UIColor orangeColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

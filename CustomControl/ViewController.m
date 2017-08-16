//
//  ViewController.m
//  CustomControl
//
//  Created by bjovov on 2017/8/9.
//  Copyright © 2017年 ovov.cn. All rights reserved.
//

#import "ViewController.h"
#import "SliderControl.h"

@interface ViewController ()

@end

@implementation ViewController
#pragma mark - LifeCycle Menthod
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    SliderControl *slider = [[SliderControl alloc]initWithFrame:CGRectMake(0, 60, TB_SLIDER_SIZE, TB_SLIDER_SIZE)];
    [slider addTarget:self action:@selector(newValue:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:slider];
}


#pragma mark - Event Response
-(void)newValue:(SliderControl*)slider{
    NSLog(@"Slider Value %d",slider.angle);
}


@end

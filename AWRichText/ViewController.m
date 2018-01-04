//
//  ViewController.m
//  AWRichText
//
//  Created by kaso on 30/10/17.
//  Copyright © 2017年 airwind. All rights reserved.
//

#import "ViewController.h"

#import "TestView.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [TestView testWithSuperView:self.view];
}

-(BOOL)shouldAutorotate{
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

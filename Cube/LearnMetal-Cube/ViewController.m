//
//  ViewController.m
//  LearnMetal-Cube
//
//  Created by XiaoXueYuan on 2019/1/17.
//  Copyright © 2019 xxy. All rights reserved.
//

#import "ViewController.h"
#import "XYMetalView.h"

@interface ViewController()

@property (weak) IBOutlet XYMetalView *metalView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end

//
//  ScrollViewController.m
//  CocoaTest
//
//  Created by yuesheng on 16/4/1.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import "ScrollViewController.h"
#import "UIView+Additions.h"

@interface ScrollViewController ()<UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation ScrollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    self.scrollView.backgroundColor = [UIColor redColor];
    self.scrollView.pagingEnabled = YES;
    [self.scrollView updateFrameHeight:160.0];
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width * 3, 160.0);
    self.scrollView.delegate = self;
    
    [self.view addSubview:self.scrollView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.scrollView.contentOffset = CGPointMake(self.view.bounds.size.width, 0);
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
}


@end

//
//  ViewController.m
//  CocoaTest
//
//  Created by yuesheng on 16/3/22.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import "ViewController.h"
#import "HMPageScroll.h"
#import "ScrollViewController.h"

@interface ViewController ()<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet HMPageScroll *pageScroll;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *iamgeUrls = @[@"http://pic.pp3.cn/uploads//allimg/111111/132205A36-5.jpg",
                           @"http://pic.pp3.cn/uploads//allimg/111110/15563RI9-7.jpg"];
    
    [self.pageScroll setupImagesUrls:iamgeUrls repeats:YES];

}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
//    CGRect bounds = [UIScreen mainScreen].bounds;
//    self.scrollView.contentOffset = CGPointMake(bounds.size.width, 0);
}
- (IBAction)btnTouchUp:(id)sender {
//    ScrollViewController *vc = [ScrollViewController new];
//    [self presentViewController:vc animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
}


@end

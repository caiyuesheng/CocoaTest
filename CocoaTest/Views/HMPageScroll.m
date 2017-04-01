//
//  HMPageScroll.m
//  nectar
//
//  Created by yuesheng on 16/3/31.
//  Copyright © 2016年 huami. All rights reserved.
//

#import "HMPageScroll.h"
#import "UIView+Additions.h"
#import "UIImageView+WebCache.h"

@interface HMPageScroll()<UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *pageViewItemView;
@property (nonatomic, strong) UIView *pageView;

@property (nonatomic, strong) NSLayoutConstraint *pageViewWidth;

@property (nonatomic, strong) NSMutableArray *views;
@property (nonatomic, strong) NSMutableArray*pageViewItemCenters;
@property (nonatomic, strong) NSMutableArray*pageViewItemWidths;
@property (nonatomic, assign) NSInteger startPage;
@property (nonatomic, assign) BOOL repeats;

@end

@implementation HMPageScroll

- (instancetype)init{
    self = [super init];
    if(self){
        [self initView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self) {
        [self initView];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self initView];
}

- (void)initView{
    self.views = [NSMutableArray new];
    
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.bounds];
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    self.pageView = [[UIView alloc]initWithFrame:CGRectMake(0.0, 0.0, 200.0, 3.0)];
    self.pageView.backgroundColor = [UIColor redColor];
    
    [self addSubview:self.scrollView];
    [self addSubview:self.pageView];
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.scrollView
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1.0
                                                      constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.scrollView
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1.0
                                                      constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.scrollView
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.scrollView
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    self.pageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.pageView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.pageView
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:10.0]];
    [self.pageView addConstraint:[NSLayoutConstraint constraintWithItem:self.pageView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1.0
                                                               constant:3.0]];
    
    self.pageViewWidth = [NSLayoutConstraint constraintWithItem:self.pageView
                                                      attribute:NSLayoutAttributeWidth
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:nil
                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                     multiplier:1.0
                                                       constant:200.0];
    [self.pageView addConstraint:self.pageViewWidth];
    
}

#pragma mark - UIScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self.scrollView == scrollView){
        CGFloat pageWidth = CGRectGetWidth(scrollView.frame);
        NSInteger page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        
        NSInteger xx = ((NSInteger)(scrollView.contentOffset.x) % (NSInteger)(CGRectGetWidth(scrollView.frame)));
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        
        if (fabs((self.startPage+1)*width - scrollView.contentOffset.x) > width) {
            self.pageViewItemView.center = [self.pageView viewWithTag:page].center;
            [self.pageViewItemView updateFrameWidth:12];
        }else{
            CGFloat sx=(self.startPage+1)*width;
            UIView * curView=[self.pageView viewWithTag:self.startPage+1];
            CGFloat dx=(NSInteger)(fabs(sx-scrollView.contentOffset.x))%((NSInteger)width)*24.0f/width;
            if (sx<scrollView.contentOffset.x) {
                [self.pageViewItemView updateFrameX:CGRectGetMinX(curView.frame) + dx];
                [self.pageViewItemView updateFrameWidth:CGRectGetWidth(curView.frame) - dx] ;
                
            }else{
                [self.pageViewItemView updateFrameWidth:CGRectGetWidth(curView.frame) - dx];
            }
        }
        if(self.repeats){
            if (page == 0) {
                //第一页往向翻
                [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.scrollView.frame) * (self.views.count - 2) + xx, 0)];
            }else if(page == self.views.count-1){
                //最后一页往前翻
                [scrollView setContentOffset:CGPointMake(xx, 0)];
            }
        }
        [self.pageView layoutIfNeeded];
    }
}

- (void)setupViews:(NSArray *)views repeats:(BOOL)repeats{
    
}

#pragma mark -

- (void)pageViewTap:(UIGestureRecognizer *)gesture{
    NSInteger index =  gesture.view.tag;
    if(self.delegate && [self.delegate respondsToSelector:@selector(pageScroll:tapAtIndex:)]){
        [self.delegate pageScroll:self tapAtIndex:index];
    }
}

- (void)setupImagesUrls:(NSArray *)imageUrls repeats:(BOOL)repeats{
    self.repeats = repeats;
    [self.views removeAllObjects];
    for (UIView *aView in self.scrollView.subviews) {
        [aView removeFromSuperview];
    }
    for (UIView *aView in self.pageView.subviews) {
        [aView removeFromSuperview];
    }
    [self.scrollView layoutIfNeeded];
    NSInteger index = 0;
    __block UIView *leftView = nil;
    if(repeats){
        for (NSString *imageUrl in imageUrls) {
            if(index == 0){
                UIImageView *imageView = [self createImageViewAtIndex:index imageUrl:[imageUrls lastObject] tag:imageUrls.count-1];
                [self.scrollView addSubview:imageView];
                [self constraintWithPageView:imageView leftView:nil lastView:NO];
                leftView = imageView;
                index++;
            }
            UIImageView *imageView = [self createImageViewAtIndex:index imageUrl:imageUrl tag:index - 1];
            [self.scrollView addSubview:imageView];
            [self constraintWithPageView:imageView leftView:leftView lastView:NO];
            leftView = imageView;
            if (index == imageUrls.count) {
                index++;
                UIImageView *imageView = [self createImageViewAtIndex:index imageUrl:[imageUrls firstObject] tag:0];
                [self.scrollView addSubview:imageView];
                [self constraintWithPageView:imageView leftView:leftView lastView:YES];
                leftView = imageView;
            }
            index++;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (imageUrls.count > 0){
                self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(self.scrollView.frame), 0);
            }else{
                self.scrollView.contentOffset = CGPointZero;
            }
        });
    }else{
        [imageUrls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIImageView *imageView = [self createImageViewAtIndex:idx imageUrl:obj tag:idx];
            [self.scrollView addSubview:imageView];
            BOOL last = idx == imageUrls.count - 1;
            [self constraintWithPageView:imageView leftView:leftView lastView:last];
            leftView = imageView;
        }];
        self.scrollView.contentOffset = CGPointZero;
    }
    
    
    //    [self.pageView updateFrameWidth:MAX(0,[imageUrls count] - 1) * 12 + MAX(0,[imageUrls count]-1) * 8 + 24];
    //
    //    for (NSInteger i = 0; i<[imageUrls count]; i++) {
    //        UIView*view = [[UIView alloc] initWithFrame:CGRectMake(14 * i, 0.0, 10, 3.0)];
    //        view.tag=i+1;
    //        view.backgroundColor = [UIColor colorWithRed:0xe8/255.0 green:0xe3/255.0 blue:0xe0/255.0 alpha:0.7];
    //        view.translatesAutoresizingMaskIntoConstraints=NO;
    //        view.layer.cornerRadius = CGRectGetHeight(self.pageView.frame) / 2.0;
    //        view.layer.masksToBounds=YES;
    //        [self.pageView addSubview:view];
    //    }
    //
    //    self.pageViewItemView = [[UIView alloc] initWithFrame:CGRectMake(2, 0, 24, 3)];
    //    self.pageViewItemView.backgroundColor = [UIColor colorWithRed:0xf7/255.0 green:0x49/255.0 blue:0x68/255.0 alpha:1.0];
    //    self.pageViewItemView.tag = 100;
    //    self.pageViewItemView.layer.cornerRadius = CGRectGetHeight(self.pageView.frame) / 2;
    //    self.pageViewItemView.layer.masksToBounds = YES;
    //    [self.pageView addSubview:self.pageViewItemView];
    //
    //    [self.pageView layoutIfNeeded];
}

- (UIImageView*)createImageViewAtIndex:(NSInteger)index imageUrl:(NSString *)imageUrl tag:(NSInteger)tag{
    UIImageView*imageView=[[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.scrollView.frame) * index, 0,CGRectGetWidth(self.scrollView.frame),CGRectGetHeight(self.scrollView.frame))];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.masksToBounds = YES;
    imageView.tag = tag;
    imageView.userInteractionEnabled=YES;
    [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pageViewTap:)]];
    [imageView sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
    [self.views addObject:imageView];
    return imageView;
}

- (void)constraintWithPageView:(UIView *)pageView leftView:(UIView *)leftView lastView:(BOOL)lastView{
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:pageView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.scrollView
                                                                attribute:NSLayoutAttributeHeight
                                                               multiplier:1.0
                                                                 constant:0.0]];
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:pageView
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.scrollView
                                                                attribute:NSLayoutAttributeWidth
                                                               multiplier:1.0
                                                                 constant:0.0]];
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:pageView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.scrollView
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0
                                                                 constant:0.0]];
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:pageView
                                                                attribute:NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.scrollView
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:0.0]];
    
    if(!leftView){
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:pageView
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0]];
    }else{
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:pageView
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:leftView
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:0.0]];
    }
    if(lastView){
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:pageView
                                                                    attribute:NSLayoutAttributeTrailing
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.scrollView
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:0.0]];
    }
}

@end

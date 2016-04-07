//
//  HMPageScroll.h
//  nectar
//
//  Created by yuesheng on 16/3/31.
//  Copyright © 2016年 huami. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HMPageScroll;

@protocol HMPageScrollDelegate<NSObject>

@optional
- (void)pageScroll:(HMPageScroll *)pageScroll tapAtIndex:(NSInteger)index;

@end

@interface HMPageScroll : UIView
@property (nonatomic, weak) id<HMPageScrollDelegate> delegate;

- (void)setupImagesUrls:(NSArray *)imageUrls repeats:(BOOL)repeats;
- (void)setupViews:(NSArray *)views repeats:(BOOL)repeats;

@end

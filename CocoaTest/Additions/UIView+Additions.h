//
//  UIView+Additions.h
//  nectar
//
//  Created by 123 on 15/12/26.
//  Copyright © 2015年 huami. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView(Additions)

- (void)updateFrameWidth:(CGFloat)width;
- (void)updateFrameHeight:(CGFloat)height;
- (void)updateFrameWidth:(CGFloat)width height:(CGFloat)height;
- (void)updateFrameX:(CGFloat)x;
- (void)updateFrameY:(CGFloat)y;
- (void)updateFrameX:(CGFloat)x y:(CGFloat)y;

@end

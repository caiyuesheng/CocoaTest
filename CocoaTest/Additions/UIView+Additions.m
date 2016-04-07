//
//  UIView+Additions.m
//  nectar
//
//  Created by 123 on 15/12/26.
//  Copyright © 2015年 huami. All rights reserved.
//

#import "UIView+Additions.h"

@implementation UIView(Additions)

- (void)updateFrameWidth:(CGFloat)width{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (void)updateFrameHeight:(CGFloat)height{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (void)updateFrameWidth:(CGFloat)width height:(CGFloat)height{
    CGRect frame = self.frame;
    frame.size.width = width;
    frame.size.height = height;
    self.frame = frame;
}

- (void)updateFrameX:(CGFloat)x{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void)updateFrameY:(CGFloat)y{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (void)updateFrameX:(CGFloat)x y:(CGFloat)y{
    CGRect frame = self.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    self.frame = frame;
}

@end

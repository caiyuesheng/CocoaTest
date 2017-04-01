//
//  UIImage+Additions.h
//  CocoaTest
//
//  Created by yuesheng on 16/11/30.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(Additions)

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius saturationDeltaFactor:(CGFloat)saturationDeltaFactor;

@end

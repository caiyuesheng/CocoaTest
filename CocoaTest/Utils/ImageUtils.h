//
//  ImageUtils.h
//  CocoaTest
//
//  Created by yuesheng on 16/3/24.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageUtils : NSObject

+ (UIImage *)fixImageOrientation:(UIImage *)image;
+ (UIImage *)fixOrientation:(UIImage *)aImage;

@end

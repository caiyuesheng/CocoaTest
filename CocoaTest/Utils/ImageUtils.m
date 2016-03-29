//
//  ImageUtils.m
//  CocoaTest
//
//  Created by yuesheng on 16/3/24.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

+ (UIImage *)fixImageOrientation:(UIImage *)image{
    if(image.imageOrientation == UIImageOrientationUp){
        return image;
    }
    CGSize size = image.size;
    CGFloat scale = image.scale;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformMakeScale(-1, 1);
            break;
        case UIImageOrientationDown:
            transform = CGAffineTransformMakeRotation(M_PI);
            break;
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformMakeRotation(M_PI);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformMakeRotation(M_PI_2);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    ciImage = [ciImage imageByApplyingTransform:transform];


    CIContext *content = [CIContext contextWithOptions:nil];
    CGImageRef processedCGImage = [content createCGImage:ciImage fromRect:ciImage.extent];
    UIImage *result = [UIImage imageWithCGImage:processedCGImage scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(processedCGImage);
    
    return result;
}

+ (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


@end

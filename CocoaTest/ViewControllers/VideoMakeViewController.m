//
//  VideoMakeViewController.m
//  CocoaTest
//
//  Created by yuesheng on 16/11/30.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import "VideoMakeViewController.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "UIImage+Additions.h"

@interface VideoMakeViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation VideoMakeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



- (IBAction)btnTouch:(id)sender{
    PHAsset *phasset = [[PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil] firstObject];
    if(!phasset){
        return;
    }
    NSLog(@"begin");
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf generatLogoVideo];
    });
//    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"视频结尾动画%03d.gif", 120]];

//    [[PHImageManager defaultManager] requestAVAssetForVideo:phasset options:nil resultHandler:^(AVAsset * asset, AVAudioMix *audioMix, NSDictionary *info) {
//        if(!asset){
//            NSLog(@"request avasset error");
//            return;
//        }
//        [weakSelf generatImage:asset];
//    }];
}

- (void)generatImage:(AVAsset *)avasset{
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:avasset];
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    imageGenerator.appliesPreferredTrackTransform = YES;
    imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CMTime actualTime;
    CMTime time = avasset.duration;
    CGFloat seconds = CMTimeGetSeconds(avasset.duration);
    NSError *error = nil;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    seconds = CMTimeGetSeconds(actualTime);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    image = [image applyBlurWithRadius:20 saturationDeltaFactor:1];
    [self generatVideo:image];
}

- (void)generatVideo:(UIImage *)image{
    NSError *error = nil;
    NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@.mp4", [[NSUUID UUID] UUIDString]]];
    NSURL *url = [NSURL fileURLWithPath:outputFielPath];
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    if(error){
        NSLog(@"error: %@", error);
        return;
    }
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: @(image.size.width),
                                    AVVideoHeightKey: @(image.size.height)};
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSDictionary *sourcePixelBufferAttributesDictionary = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB)};
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    if(![assetWriter canAddInput:writerInput]){
        NSLog(@"can not add input");
        return;
    }
    [assetWriter addInput:writerInput];
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:image.CGImage size:image.size];
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    __block int frame = 0;
    __weak typeof(self) weakSelf = self;
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while([writerInput isReadyForMoreMediaData]){
            if(frame >= 30){
                [writerInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^{
                    CFRelease(buffer);
//                    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
//                    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
//                        if (error) {
//                            NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
//                        }
//                        NSLog(@"成功保存视频到相簿.");
//                    }];
                    [weakSelf addLogoImage:outputFielPath];
                }];
                
                break;
            }
            
            if (buffer){
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 30)])
                    NSLog(@"FAIL");
                else
                    NSLog(@"Success:%d", frame);
            }
            frame ++;
        }
    }];
}

- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size{
    NSDictionary *options = @{(NSString *)kCVPixelBufferCGImageCompatibilityKey: @(YES),
                              (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES)};
    
    CVPixelBufferRef pxbuffer = NULL;
    
//    CGFloat frameWidth = CGImageGetWidth(image);
//    CGFloat frameHeight = CGImageGetHeight(image);
    
//    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
//                                          frameWidth,
//                                          frameHeight,
//                                          kCVPixelFormatType_32ARGB,
//                                          (__bridge CFDictionaryRef) options,
//                                          &pxbuffer);
    
    CGFloat frameWidth = size.width;
    CGFloat frameHeight = size.height;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, frameWidth, frameHeight), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)addLogoImage:(NSString *)file{
    AVAsset *avasset = [AVAsset assetWithURL:[NSURL fileURLWithPath:file]];
    
    UIImage *image = [UIImage imageNamed:@"180"];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc]init];
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *errorVideo = nil;
    AVAssetTrack *videoAssetTrack = [[avasset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if(![videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, avasset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:&errorVideo]){
        NSLog(@"audio insert error: %@", errorVideo);
    }
    CGSize size = videoAssetTrack.naturalSize;
    CALayer *overlayLayer1 = [CALayer layer];
    [overlayLayer1 setContents:(id)[image CGImage]];
    if(size.width > size.height){
        overlayLayer1.frame = CGRectMake((size.width - size.height - 180) / 2, 90 , size.height - 180, size.height - 180);
    }else{
        overlayLayer1.frame = CGRectMake(90, (size.height - size.width + 180) / 2, size.width - 180, size.width - 180);
    }
    
    [overlayLayer1 setMasksToBounds:YES];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 1.0;
    animation.fromValue=[NSNumber numberWithFloat:0.0];
    animation.toValue=[NSNumber numberWithFloat:1.0];
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    animation.removedOnCompletion = NO;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        [overlayLayer1 addAnimation:animation forKey:@"animateOpacity"];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer1];
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, avasset.duration);
    instruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = size;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    videoComp.instructions = @[instruction];
    
    NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@.mp4", [[NSUUID UUID] UUIDString]]];
    
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    assetExport.videoComposition = videoComp;
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    assetExport.outputURL = [NSURL fileURLWithPath:outputFielPath];
    assetExport.shouldOptimizeForNetworkUse = YES;
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        switch ([assetExport status]) {
            case AVAssetExportSessionStatusCompleted:{
                ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
                [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:outputFielPath] completionBlock:^(NSURL *assetURL, NSError *error) {
                    if (error) {
                        NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
                    }
                    NSLog(@"成功保存视频到相簿.");
                }];
            }
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"export error: %@", assetExport.error);
                break;
            default:
                break;
        }
    }];
}


- (void)generatLogoVideo{

    NSError *error = nil;
    NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@.mp4", [[NSUUID UUID] UUIDString]]];
    NSURL *url = [NSURL fileURLWithPath:outputFielPath];
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    if(error){
        NSLog(@"error: %@", error);
        return;
    }
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: @(1080),
                                    AVVideoHeightKey: @(1080)};
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSDictionary *sourcePixelBufferAttributesDictionary = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB)};
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    if(![assetWriter canAddInput:writerInput]){
        NSLog(@"can not add input");
        return;
    }
    [assetWriter addInput:writerInput];
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    __block int frame = 0;
//    __weak typeof(self) weakSelf = self;
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while([writerInput isReadyForMoreMediaData]){
            if(frame > 119){
                [writerInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^{
                    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
                    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
                        if (error) {
                            NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
                        }
                        NSLog(@"成功保存视频到相簿.");
                    }];
//                    [weakSelf addLogoImage:outputFielPath];
                }];
                
                break;
            }
//            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"视频结尾动画%03d.gif", frame + 1]];
//            CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:image.CGImage size:CGSizeMake(1080, 1080)];
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"频尾动画_00%03d.png", frame]];
            CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:image.CGImage size:CGSizeMake(900, 900)];
            if (buffer){
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 30)])
                    NSLog(@"FAIL");
                else
                    NSLog(@"Success:%d", frame);
                CFRelease(buffer);
            }
            frame ++;
        }
    }];
}

@end

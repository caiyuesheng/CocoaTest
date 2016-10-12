//
//  VideoUtil.m
//  CocoaTest
//
//  Created by yuesheng on 16/6/17.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import "VideoUtil.h"
#import <AVFoundation/AVFoundation.h>

@implementation VideoUtil

+ (void)mergeAndExportVideos:(NSArray*)videosPathArray withOutPath:(NSString*)outpath completionCallback:(void (^)(NSURL *finalFilePath, NSError *error))completion{
    if (videosPathArray.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @try {
            AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
            AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
            CMTime totalDuration = kCMTimeZero;
            for (int i = 0; i < videosPathArray.count; i++) {
                AVURLAsset *asset = [AVURLAsset assetWithURL:videosPathArray[i]];
                NSError *erroraudio = nil;
                //获取AVAsset中的音频 或者视频
                AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                //向通道内加入音频或者视频
                BOOL ba = [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                              ofTrack:assetAudioTrack
                                               atTime:totalDuration
                                                error:&erroraudio];
                
                NSLog(@"erroraudio:%@%d",erroraudio,ba);
                NSError *errorVideo = nil;
                AVAssetTrack *assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
                BOOL bl = [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                              ofTrack:assetVideoTrack
                                               atTime:totalDuration
                                                error:&errorVideo];
                
                NSLog(@"errorVideo:%@%d",errorVideo,bl);
                totalDuration = CMTimeAdd(totalDuration, asset.duration);
            }
            
            videoTrack.preferredTransform = CGAffineTransformMakeRotation(M_PI_2);
            NSInteger width = MIN(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
            CGSize renderSize = CGSizeMake(width, width);
            
            AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition new];
            videoComposition.renderSize = renderSize;
            videoComposition.frameDuration = CMTimeMake(1, (int)videoTrack.nominalFrameRate);

            AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(kCMTimeZero, totalDuration));
            
            AVMutableVideoCompositionLayerInstruction *transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            CGAffineTransform t1,t2;
            if(videoTrack.naturalSize.width > videoTrack.naturalSize.height){
                t1 = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, -(videoTrack.naturalSize.width-videoTrack.naturalSize.height)/2);
            }else{
                t1 = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, -(videoTrack.naturalSize.height-videoTrack.naturalSize.width)/2);
            }
            t2 = CGAffineTransformRotate(t1, M_PI_2);
            CGAffineTransform finalTransform = t2;
            
            [transformer setTransform:finalTransform atTime:kCMTimeZero];
            instruction.layerInstructions = @[transformer];
            videoComposition.instructions = @[instruction];
            
            NSURL *mergeFileURL = [NSURL fileURLWithPath:outpath];
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                              presetName:AVAssetExportPresetMediumQuality];
            exporter.outputURL = mergeFileURL;
            exporter.outputFileType = AVFileTypeMPEG4;
            exporter.shouldOptimizeForNetworkUse = YES;
            exporter.videoComposition = videoComposition;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                switch ([exporter status]) {
                    case AVAssetExportSessionStatusFailed:{
                        NSLog(@"Export session faiied with error: %@", [exporter error]);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil, exporter.error);
                        });
                    }
                        break;
                    case AVAssetExportSessionStatusCompleted:{
                        NSLog(@"Successful");
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [VideoUtil videoUrl:mergeFileURL withText:@"text is in video" completionCallback:completion];
                        });
                    }
                        break;
                    default:
                        
                        break;
                }
            }];
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception description]);
            NSError *error = [NSError errorWithDomain:@"huami" code:100 userInfo:@{NSLocalizedDescriptionKey: [exception description]}];
            completion(nil, error);
        }
        @finally {
            
        }
    });
}

+ (void)videoUrl:(NSURL *)outputFileURL withText:(NSString *)text  completionCallback:(void (^)(NSURL *finalFilePath, NSError *error))completion{
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:outputFileURL options:nil];
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo  preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:clipVideoTrack
                                    atTime:kCMTimeZero error:nil];
    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
    
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:clipAudioTrack atTime:kCMTimeZero error:nil];

    CGSize videoSize=[compositionVideoTrack naturalSize];
    
    
    CALayer *animatedTitleLayer = [CALayer layer];
    CATextLayer *titleLayer = [[CATextLayer alloc] init];
    titleLayer.string = @"text in video";
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.bounds = CGRectMake(0, 0, videoSize.width / 2, videoSize.height / 2);
    titleLayer.opacity = 1.0;
    
    [animatedTitleLayer addSublayer:titleLayer];
    animatedTitleLayer.position = CGPointMake(videoSize.width / 2.0, videoSize.height / 2.0);

    // build a Core Animation tree that contains both the animated title and the video.
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:animatedTitleLayer];

    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                                                                                           inLayer:parentLayer];
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComp.instructions = [NSArray arrayWithObject: instruction];
    
    NSString *resource = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"mp3"];
    AVURLAsset *audioAssert = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:resource] options:nil];
    AVAssetTrack *audioTrack = [[audioAssert tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    AVMutableCompositionTrack *mixAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [mixAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
    
    NSString* videoName = @"mynewwatermarkedvideo.mov";
    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]){
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }
    
    AVAssetExportSession *_assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];//AVAssetExportPresetPassthrough
    _assetExport.videoComposition = videoComp;
    _assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    _assetExport.outputURL = exportUrl;
    _assetExport.shouldOptimizeForNetworkUse = YES;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:^(void ) {
        switch ([_assetExport status]) {
            case AVAssetExportSessionStatusFailed:{
                NSLog(@"Export session faiied with error: %@", [_assetExport error]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, _assetExport.error);
                });
            }
                break;
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"Successful");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(exportUrl, nil);
                });
            }
                break;
            default:
                
                break;
        }

    }];
}

@end

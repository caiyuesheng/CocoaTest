//
//  VideoUtil.h
//  CocoaTest
//
//  Created by yuesheng on 16/6/17.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoUtil : UIView

+ (void)mergeAndExportVideos:(NSArray*)videosPathArray withOutPath:(NSString*)outpath completionCallback:(void (^)(NSURL *finalFilePath , NSError *error))completion;

@end

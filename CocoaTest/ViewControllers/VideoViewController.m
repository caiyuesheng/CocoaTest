//
//  VideoViewController.m
//  CocoaTest
//
//  Created by yuesheng on 16/6/17.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import "VideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "VideoUtil.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface VideoViewController ()<AVCaptureFileOutputRecordingDelegate>
@property (weak, nonatomic) IBOutlet UIView *viewContainer;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *labelCount;
@property (strong,nonatomic) AVCaptureSession *captureSession;//负责输入和输出设备之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层
@property (assign,nonatomic) BOOL enableRotation;//是否允许旋转（注意在视频录制过程中禁止屏幕旋转）
@property (assign,nonatomic) CGRect *lastBounds;//旋转的前大小
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;//后台任务标识

@property (nonatomic, strong) NSMutableArray *movies;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.movies = [NSMutableArray new];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _captureSession = [[AVCaptureSession alloc]init];
    [_captureSession beginConfiguration];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    //获得输入设备
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    if (!captureDevice) {
        NSLog(@"取得后置摄像头时出现问题.");
        return;
    }
    
    //添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    NSError *error=nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    AVCaptureDeviceInput *audioCaptureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    //初始化设备输出对象，用于获得输出数据
    _captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:audioCaptureDeviceInput];
        //添加防抖动功能
        AVCaptureConnection *captureConnection=[_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported ]) {
            captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
        }
    }
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }
    
    //创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    CALayer *layer = self.viewContainer.layer;
    layer.masksToBounds = YES;
    
    _captureVideoPreviewLayer.frame = layer.bounds;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    //将视频预览层添加到界面中
    [layer addSublayer:_captureVideoPreviewLayer];
    
    [self addGenstureRecognizer];
    
    //提交会话配置
    [self.captureSession commitConfiguration];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.captureSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.captureSession stopRunning];
}


- (IBAction)btnTouchUp:(id)sender {
    [self takeButtonClick:sender];
}

- (IBAction)btnMerginMovie:(id)sender{
    NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:@"MyMovie.mp4"];
    unlink([outputFielPath UTF8String]);
    self.label.text = @"开始合成...";
    [VideoUtil mergeAndExportVideos:self.movies withOutPath:outputFielPath completionCallback:^(NSURL *finalFilePath, NSError *error) {
        if(!finalFilePath){
            self.label.text = [error description];
            return;
        }
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
        UIBackgroundTaskIdentifier lastBackgroundTaskIdentifier = self.backgroundTaskIdentifier;
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:finalFilePath completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
                self.label.text = @"合成结束，出现异常2...";
                return;
            }
            if (lastBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:lastBackgroundTaskIdentifier];
            }
            self.label.text = @"合成结束，成功保存视频到相簿...";
            NSLog(@"成功保存视频到相簿.");
        }];
    }];
}


- (void)takeButtonClick:(UIButton *)sender {
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording]) {
        self.enableRotation=NO;
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@.mp4", [[NSUUID UUID] UUIDString]]];
        unlink([outputFielPath UTF8String]);
        NSURL *fileUrl=[NSURL fileURLWithPath:outputFielPath];
        [self.captureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    }
    else{
        [self.captureMovieFileOutput stopRecording];//停止录制
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
    self.label.text = @"开始录制...";
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"视频录制完成.");
    self.label.text = @"视频录制完成.";
    //视频录入完成之后在后台将视频存储到相簿
    self.enableRotation=YES;
    [self.movies addObject:outputFileURL];
    self.labelCount.text = [NSString stringWithFormat:@"视频数:%ld",(long)self.movies.count];
//    UIBackgroundTaskIdentifier lastBackgroundTaskIdentifier = self.backgroundTaskIdentifier;
//    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
//    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
//    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
//        if (error) {
//            NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
//        }
//        if (lastBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
//            [[UIApplication sharedApplication] endBackgroundTask:lastBackgroundTaskIdentifier];
//        }
//        NSLog(@"成功保存视频到相簿.");
//    }];
}

#pragma mark - Method

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

/**
 *  添加点按手势，点按时聚焦
 */
-(void)addGenstureRecognizer{
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.viewContainer addGestureRecognizer:tapGesture];
}

-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    CGPoint point= [tapGesture locationInView:self.viewContainer];
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint= [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

@end

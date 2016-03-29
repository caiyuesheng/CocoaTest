//
//  AVCaptureViewController.m
//  CocoaTest
//
//  Created by yuesheng on 16/3/23.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import "AVCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface AVCaptureViewController ()
@property (nonatomic, strong) UIView *localView;
@property (nonatomic, strong) AVCaptureSession *avCaptureSession;
@property (nonatomic, strong) AVCaptureDevice *avCaptureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *avCaptureVideoDataOutput;
@property (nonatomic, strong) AVCaptureStillImageOutput *avCaptureStillImageOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) BOOL takePictureFrame;
@property (nonatomic, assign) CGFloat frameScale;
@property (nonatomic, assign) AVCaptureDevicePosition cameraDevice;

@end

@implementation AVCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.frameScale = 1.0;
    self.cameraDevice = AVCaptureDevicePositionBack;
    
    self.takePictureFrame = NO;
    [self createControl];
    [self startVideoCapture];
    [self initPinchGesture];
}

- (void)dealloc{
    [self stopVideoCapture:nil];
}

- (void)createControl{
    //UI展示
    self.view.backgroundColor= [UIColor grayColor];
    
    self.localView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.localView];
    
    UIView *bottomBarBgView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-60, self.view.bounds.size.width, 60)];
    bottomBarBgView.backgroundColor = [UIColor redColor];
    [self.localView addSubview:bottomBarBgView];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [backBtn addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setFrame:CGRectMake(10, 5, 60, 44)];
    [backBtn setTitle:@"Back" forState:UIControlStateNormal];
    [bottomBarBgView addSubview:backBtn];
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cameraBtn.frame = CGRectMake(120, 5, 80, 44);
    [cameraBtn setTitle:@"TakePhoto" forState:UIControlStateNormal];
    [cameraBtn addTarget:self action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
    [bottomBarBgView addSubview:cameraBtn];
    
    UIImage *deviceImage = [UIImage imageNamed:@"camera_button_switch_camera.png"];
    
    UIButton *deviceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [deviceBtn setBackgroundImage:deviceImage forState:UIControlStateNormal];
    [deviceBtn addTarget:self action:@selector(swapFrontAndBackCameras:) forControlEvents:UIControlEventTouchUpInside];
    [deviceBtn setFrame:CGRectMake(250, 20, deviceImage.size.width, deviceImage.size.height)];
    [self.localView addSubview:deviceBtn];
}

- (AVCaptureDevice *)getCameraDevice:(AVCaptureDevicePosition) devicePosition{
    //获取前置摄像头设备
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras){
        if (device.position == devicePosition)
            return device;
    }
    
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

- (void)startVideoCapture{
    //打开摄像设备，并开始捕抓图像
    if(self.avCaptureDevice || self.avCaptureSession){
        return;
    }
    
    if((self.avCaptureDevice = [self getCameraDevice:self.cameraDevice]) == nil){
        return;
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.avCaptureDevice error:&error];
    if (!videoInput){
        self.avCaptureDevice = nil;
        return;
    }
    
    self.videoInput = videoInput;
    self.avCaptureSession = [[AVCaptureSession alloc] init];
    self.avCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    [self.avCaptureSession addInput:videoInput];
    
    AVCaptureStillImageOutput *avCaptureStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary*settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                             [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                             nil];
    avCaptureStillImageOutput.outputSettings = settings;
    self.avCaptureStillImageOutput = avCaptureStillImageOutput;
    [self.avCaptureSession addOutput:avCaptureStillImageOutput];
    
    
    AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.avCaptureSession];
    previewLayer.frame = CGRectMake(0, 0, self.localView.bounds.size.width, self.localView.bounds.size.height-60);
    previewLayer.videoGravity= AVLayerVideoGravityResizeAspectFill;
    
    [self.localView.layer insertSublayer:previewLayer atIndex:0];
    self.previewLayer = previewLayer;
    [self.avCaptureSession startRunning];
}

- (void)stopVideoCapture:(id)arg{
    //停止摄像头捕抓
    if(self.avCaptureSession){
        [self.avCaptureSession stopRunning];
        [self.avCaptureSession removeInput:self.videoInput];
        self.videoInput = nil;
        
        [self.avCaptureSession removeOutput:self.avCaptureVideoDataOutput];
        self.avCaptureVideoDataOutput = nil;
        self.avCaptureSession= nil;
    }
    
    self.avCaptureDevice= nil;
    //移除localView里面的预览内容
    
    for(CALayer *layer in self.localView.layer.sublayers){
        if ([layer isKindOfClass:[AVCaptureVideoPreviewLayer class]]){
            [layer removeFromSuperlayer];
            return;
        }
    }
    self.previewLayer = nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the buffer*/
    if(CVPixelBufferLockBaseAddress(pixelBuffer, 0) == kCVReturnSuccess){
        //UInt8 *bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddress(pixelBuffer);
        //size_t buffeSize = CVPixelBufferGetDataSize(pixelBuffer);
        
        if(self.takePictureFrame){
            self.takePictureFrame = NO;
            
            //第一次数据要求：宽高，类型
            //int width_1 = CVPixelBufferGetWidth(pixelBuffer);
            //int height_1 = CVPixelBufferGetHeight(pixelBuffer);
            
            /*Create a CGImageRef from the CVImageBufferRef*/
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            /*Lock the image buffer*/
            CVPixelBufferLockBaseAddress(imageBuffer,0);
            
            uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
            size_t width = CVPixelBufferGetWidth(imageBuffer);
            size_t height = CVPixelBufferGetHeight(imageBuffer);
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
            CGImageRef newImage = CGBitmapContextCreateImage(newContext);
            
            /*We release some components*/
            CGContextRelease(newContext);
            CGColorSpaceRelease(colorSpace);
            UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
            
            /*We relase the CGImageRef*/
            CGImageRelease(newImage);
            
            [self performSelectorOnMainThread:@selector(takeImageFinished:) withObject:image waitUntilDone:NO];
            
            /*We unlock the  image buffer*/
            CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        }
        
        /*We unlock the buffer*/
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
}

-(UIImage *) getImageBySampleBuffer:(CMSampleBufferRef)sampleBuffer{
    UIImage *image = nil;
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    /*Lock the buffer*/
    if(CVPixelBufferLockBaseAddress(pixelBuffer, 0) == kCVReturnSuccess){
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
        
        /*We relase the CGImageRef*/
        CGImageRelease(newImage);
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        /*We unlock the buffer*/
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    return image;
}


#pragma mark - button response

//切换前、后置摄像头

- (void)swapFrontAndBackCameras:(id)sender {
    if (self.cameraDevice == AVCaptureDevicePositionBack ) {
        self.cameraDevice = AVCaptureDevicePositionFront;
    }else {
        self.cameraDevice = AVCaptureDevicePositionBack;
    }
    
    self.avCaptureDevice = [self getCameraDevice:self.cameraDevice];
    [[self.previewLayer session] beginConfiguration];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.avCaptureDevice error:nil];
    for (AVCaptureInput *oldInput in [[self.previewLayer session] inputs]) {
        [[self.previewLayer session] removeInput:oldInput];
    }
    
    [[self.previewLayer session] addInput:input];
    [[self.previewLayer session] commitConfiguration];
}

- (void)closeView{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)takePicture{
    [self.avCaptureStillImageOutput captureStillImageAsynchronouslyFromConnection:[self connectionWithMediaType:AVMediaTypeVideo fromConnections:self.avCaptureStillImageOutput.connections] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (error.code == 0 || error == nil){
            UIImage *image = [self getImageBySampleBuffer:imageDataSampleBuffer];
            [self performSelectorOnMainThread:@selector(takeImageFinished:) withObject:image waitUntilDone:NO];
        }
    }];
}

-(void) takeImageFinished:(UIImage *)aImage{
    UIImageWriteToSavedPhotosAlbum(aImage, nil, nil, nil);
    
    [self dismissViewControllerAnimated:NO completion:NULL];
}

-(AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections{
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}

-(void) initPinchGesture{
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                        initWithTarget:self
                                                        action:@selector(handlePinch:)];
    
    [self.localView addGestureRecognizer:pinchGestureRecognizer];
}

- (void) handlePinch:(UIPinchGestureRecognizer*) recognizer{
    if ((self.frameScale * recognizer.scale) < 1.0)
        return;
    
    if (recognizer.scale > self.avCaptureDevice.activeFormat.videoMaxZoomFactor)
        return;
    
    self.frameScale = self.frameScale * recognizer.scale;
    [self.avCaptureDevice lockForConfiguration:nil];
    self.avCaptureDevice.videoZoomFactor = self.frameScale;
    [self.avCaptureDevice unlockForConfiguration];
    
    recognizer.scale = 1;
}


@end

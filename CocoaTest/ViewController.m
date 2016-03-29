//
//  ViewController.m
//  CocoaTest
//
//  Created by yuesheng on 16/3/22.
//  Copyright © 2016年 yuesheng. All rights reserved.
//

#import "ViewController.h"
#import "AFAppDotNetAPIClient.h"
#import "ImageUtils.h"

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)btnTouchUp:(id)sender {
    UIImagePickerController *pc = [UIImagePickerController new];
    pc.delegate = self;
    pc.sourceType = UIImagePickerControllerSourceTypeCamera;
    pc.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    [self presentViewController:pc animated:YES completion:nil];
}

- (IBAction)btnTransfromTouchUp:(id)sender {
    
    self.imageView.transform = CGAffineTransformMakeScale(-1, 1);
}

#pragma mark -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    UIImage *temp = [ImageUtils fixImageOrientation:image];
    self.imageView.image = temp;
    
//    [self uploadImage:temp];
}


- (void)uploadImage:(UIImage *)image{
    NSString *url = @"common/uploadFile/?guest=y";
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,  NSUserDomainMask,  YES) ;
    NSString *documentsDirectory =  [paths objectAtIndex:0];
    NSString *file = [documentsDirectory stringByAppendingPathComponent:@"image.jpg"] ;
    
    [imageData writeToFile:file atomically:YES];
    
    
    AFAppDotNetAPIClient *client = [AFAppDotNetAPIClient sharedClient];
    [client POST:url parameters:@{@"type":@"user"} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSURL *url = [NSURL fileURLWithPath:file];
        NSError *err;
        [formData appendPartWithFileURL:url name:@"Filedata" error:&err];
        if(err){
            NSLog(@"err:%@", err);
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"progress----- %.2f",((CGFloat)uploadProgress.completedUnitCount)/((CGFloat)uploadProgress.totalUnitCount));
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"success:%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error:%@", error);
    }];
}

- (void)testHttp{
    NSString *url = @"post/get/7169/?guest=y";
    AFAppDotNetAPIClient *client = [AFAppDotNetAPIClient sharedClient];
    [client POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@", responseObject);
        id s = [responseObject objectForKey:@"associatedPost"];
        NSLog(@"%@", s);
        if(s && [s isKindOfClass:[NSNull class]]){
            NSLog(@"s=true");
        }else{
            NSLog(@"s=false");
        }
            
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error:%@",error);
    }];
}

@end

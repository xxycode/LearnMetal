//
//  ViewController.m
//  LearnMetal
//
//  Created by XiaoXueYuan on 2019/1/7.
//  Copyright © 2019 xxy. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XYMetalView.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak) IBOutlet XYMetalView *metalView;

@property (nonatomic, strong) AVCaptureSession *mCaptureSession;

@property (nonatomic, strong) AVCaptureScreenInput *mCaptureDeviceInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *mCaptureDeviceOutput;

@property (nonatomic, strong) dispatch_queue_t mProcessQueue;

@property (nonatomic) CVMetalTextureCacheRef textureCache;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCaptureSession];
    // Do any additional setup after loading the view.
}

- (void)setupCaptureSession {
    self.mCaptureSession = [[AVCaptureSession alloc] init];
    self.mCaptureSession.sessionPreset = AVCaptureSessionPresetMedium;
    self.mProcessQueue = dispatch_queue_create("mProcessQueue", DISPATCH_QUEUE_SERIAL); // 串行队列
    self.mCaptureDeviceInput = [[AVCaptureScreenInput alloc] init];
    if ([self.mCaptureSession canAddInput:self.mCaptureDeviceInput]) {
        [self.mCaptureSession addInput:self.mCaptureDeviceInput];
    }
    self.mCaptureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.mCaptureDeviceOutput setAlwaysDiscardsLateVideoFrames:NO];
    // 这里设置格式为BGRA，而不用YUV的颜色空间，避免使用Shader转换
    [self.mCaptureDeviceOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.mCaptureDeviceOutput setSampleBufferDelegate:self queue:self.mProcessQueue];
    if ([self.mCaptureSession canAddOutput:self.mCaptureDeviceOutput]) {
        [self.mCaptureSession addOutput:self.mCaptureDeviceOutput];
    }
    AVCaptureConnection *connection = [self.mCaptureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait]; // 设置方向
    [self.mCaptureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    [self.metalView renderPixelBuffer:pixelBuffer size:CGSizeMake(width, height) pixelFormat:MTLPixelFormatBGRA8Unorm];
    
}


@end

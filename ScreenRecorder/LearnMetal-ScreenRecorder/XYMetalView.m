//
//  XYMetalView.m
//  LearnMetal
//
//  Created by XiaoXueYuan on 2019/1/10.
//  Copyright © 2019 xxy. All rights reserved.
//

#import "XYMetalView.h"
#import <Metal/Metal.h>
#import <Quartz/Quartz.h>
#import "XYShaderTypes.h"

@interface XYMetalView()

@property (nonatomic, strong) id <MTLDevice> device;

@property (nonatomic, strong) CAMetalLayer *metalLayer;

@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;

@property (nonatomic, strong) id <MTLTexture> texture;

@property (nonatomic, assign) CVMetalTextureCacheRef textureCache; //output

@property (nonatomic, strong) id <MTLTexture> maskTexture;

@end

@implementation XYMetalView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonInit];
}


- (void)commonInit {
    self.wantsLayer = YES;
    self.device = MTLCreateSystemDefaultDevice();
    self.metalLayer = [CAMetalLayer layer];
    self.metalLayer.frame = self.bounds;
    self.metalLayer.device = self.device;
    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
    [self.layer addSublayer:self.metalLayer];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self setupPipeLine];
    [self setupMaskTexture];
}

- (void)setupMaskTexture {
    NSImage *image = [NSImage imageNamed:@"4"];
    NSData* cocoaData = [image TIFFRepresentation];
    CFDataRef carbonData = (__bridge CFDataRef)cocoaData;
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData(carbonData, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8 *rawData = malloc(width * height * 4 * sizeof(uint8));
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * width;
    int bitsPerComponent = 8;
    CGContextRef bitmapContext = CGBitmapContextCreate(rawData,
                                                       width,
                                                       height,
                                                       bitsPerComponent,
                                                       bytesPerRow,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast | kCGImageByteOrder32Big);
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, width, height), imageRef);
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:width height:height mipmapped:NO];
    self.maskTexture = [self.device newTextureWithDescriptor:textureDescriptor];
    MTLRegion regin = MTLRegionMake2D(0, 0, width, height);
    [self.maskTexture replaceRegion:regin mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    free(rawData);
}

- (void)render {
    id <CAMetalDrawable> drawable = self.metalLayer.nextDrawable;
    if (drawable) {
        MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.48, 0.74, 0.92, 1);
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        id <MTLCommandQueue> commandQueue = [self.device newCommandQueue];
        id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [commandEncoder setRenderPipelineState:self.pipelineState];
        XYVertex vertices[] = {
            //采集画面顶点
            //顶点坐标 纹理坐标 透明度
            {{-1, -1},{0, 1},1},
            {{-1, 1},{0, 0},1},
            {{1, -1},{1, 1},1},
            {{1, 1},{1, 0},1},
            //水印顶点
            {{-1, 1},{0, 0},0.5},
            {{-1, 0.7},{0, 1},0.5},
            {{-0.7, 1},{1, 0},0.5},
            {{-0.7, 0.7},{1, 1},0.5},
        };
        [commandEncoder setVertexBytes:vertices length:sizeof(vertices) atIndex:XYVertexMainVertices];
        [commandEncoder setFragmentTexture:self.texture atIndex:XYTextureIndexBaseContent];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [commandEncoder setFragmentTexture:self.maskTexture atIndex:XYTextureIndexBaseContent];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:4 vertexCount:4];
        [commandEncoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer size:(CGSize)size pixelFormat:(MTLPixelFormat)pixelFormat {
    CVMetalTextureRef tmpTexture = NULL;
    // 如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
    //CGFloat scale = NSScreen.mainScreen.backingScaleFactor;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, pixelFormat, size.width, size.height, 0, &tmpTexture);
    
    if(status == kCVReturnSuccess) {
        self.texture = CVMetalTextureGetTexture(tmpTexture);
        CFRelease(tmpTexture);
        [self render];
    }
}

- (void)setupPipeLine {
    id <MTLLibrary> library = [self.device newDefaultLibrary];
    id <MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexShader"];
    id <MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = self.metalLayer.pixelFormat;
    MTLRenderPipelineColorAttachmentDescriptor *renderbufferAttachment = pipelineDescriptor.colorAttachments[0];
    renderbufferAttachment.blendingEnabled = YES; //启用混合
    renderbufferAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    renderbufferAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    renderbufferAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    renderbufferAttachment.sourceAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    renderbufferAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    renderbufferAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
}

@end

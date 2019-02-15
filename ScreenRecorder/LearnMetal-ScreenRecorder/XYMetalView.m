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
            {{-1, -1},{0, 1}},
            {{-1, 1},{0, 0}},
            {{1, -1},{1, 1}},
            {{1, 1},{1, 0}}
        };
        [commandEncoder setVertexBytes:vertices length:sizeof(vertices) atIndex:XYVertexInputRGBVertices];
        [commandEncoder setFragmentTexture:self.texture atIndex:XYTextureIndexBaseColor];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
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
    renderbufferAttachment.sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    renderbufferAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    renderbufferAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
}

@end

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
    [self.layer addSublayer:self.metalLayer];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self setupPipeLine];
    [self render];
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
            {{0.5, -0.5},{1, 0, 0, 1}},
            {{-0.5, -0.5},{0, 1, 0, 1}},
            {{0, 0.5},{0, 0, 1, 1}}
        };
        [commandEncoder setVertexBytes:vertices length:sizeof(XYVertex) * 3 atIndex:XYVertexInputIndexVertices];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [commandEncoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
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

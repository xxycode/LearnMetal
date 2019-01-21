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

@property (nonatomic, strong) id <MTLBuffer> vertexBuffer;

@property (nonatomic, strong) id <MTLBuffer> indexBuffer;

@property (nonatomic, strong) id <MTLDepthStencilState> depthStencilState;

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
    //[self setupDepthStencilState];
    [self setupBuffer];
    [self render];
}

- (void)setupDepthStencilState {
    MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDescriptor.depthWriteEnabled = YES;
    self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
}

- (void)setupBuffer {
    XYVertex vertices[] = {
        //前面4个点
        {{1, -0.5, 0.5},{1, 0, 0, 1}},
        {{-0.5, -0.5, 0.5},{0, 1, 0, 1}},
        {{-0.5, 0.5, 0.5},{0, 0, 1, 1}},
        {{0.5, 0.5, 0.5},{0, 1, 1, 1}},
        //后面4个点
        {{0.5, -0.5, -0.5},{1, 0, 0, 1}},
        {{-0.5, -0.5, -0.5},{0, 1, 0, 1}},
        {{-0.5, 0.5, -0.5},{0, 0, 1, 1}},
        {{0.5, 0.5, -0.5},{0, 1, 1, 1}},
    };
    self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceCPUCacheModeDefaultCache];
    
    uint16_t indices[] = {
        0, 1, 2, 2, 3, 0,
        0, 3, 7, 7, 4, 0,
        0, 1, 5, 5, 4, 0,
        2, 6, 7, 7, 3, 2,
        2, 6, 5, 5, 1, 2,
        4, 5, 6, 6, 7, 4,
    };
    
    self.indexBuffer = [self.device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceCPUCacheModeDefaultCache];
    self.indexBuffer.label = @"Indices";
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
        [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
//        [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:6 indexType:MTLIndexTypeUInt16 indexBuffer:self.indexBuffer indexBufferOffset:0];
//        [commandEncoder setDepthStencilState:self.depthStencilState];
//        [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
//        [commandEncoder setCullMode:MTLCullModeBack];
        [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:3 indexType:MTLIndexTypeUInt16 indexBuffer:self.indexBuffer indexBufferOffset:0];
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
    
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
}

@end

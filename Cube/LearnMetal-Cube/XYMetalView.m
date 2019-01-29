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
#import "MatrixTool.h"

@interface XYMetalView() {
    float _rz;
    float _rx;
    BOOL _mouseDown;
    CGPoint _downPoint;
}

@property (nonatomic, strong) id <MTLDevice> device;

@property (nonatomic, strong) CAMetalLayer *metalLayer;

@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;

@property (nonatomic, strong) id <MTLBuffer> vertexBuffer;

@property (nonatomic, strong) id <MTLBuffer> indexBuffer;

@property (nonatomic, assign) NSUInteger indexCount;

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
    _rz = 0.5 * M_PI;
    _rx = -0.5;
    [self.layer addSublayer:self.metalLayer];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self setupPipeLine];
    [self setupBuffer];
    [self render];
    [NSTimer scheduledTimerWithTimeInterval:0.016 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
}

- (void)setupBuffer {
    CGFloat h = 0.5;
    CGFloat w = 0.5;
    XYVertex vertices[] = {
             // 顶点坐标               顶点颜色
        {{-w, h,     0.0f},  {0.0f, 0.0f, 0.5f}},
        {{-w, -h,    0.0f},  {0.0f, 0.0f, 0.5f}},
        {{0,  0.0f,  0.8f},  {0.0f, 0.0f, 0.5f}},
        
        {{-w, -h,    0.0f},  {0.0f, 0.5f, 0.0f}},
        {{w,  -h,    0.0f},  {0.0f, 0.5f, 0.0f}},
        {{0,  0.0f,  0.8f},  {0.0f, 0.5f, 0.0f}},
        
        {{w,  -h,    0.0f},  {0.5f, 0.0f, 1.0f}},
        {{w,   h,    0.0f},  {0.5f, 0.0f, 1.0f}},
        {{0,  0.0f,  0.8f},  {0.5f, 0.0f, 1.0f}},
        
        {{w,  h,     0.0f},  {0.5f, 0.0f, 0.0f}},
        {{-w, h,     0.0f},  {0.5f, 0.0f, 0.0f}},
        {{0,  0.0f,  0.8f},  {0.5f, 0.0f, 0.0f}},
        
        {{-w,   h,   0.0f},  {1.0f, 1.0f, 1.0f}},
        {{-w,  -h,   0.0f},  {1.0f, 1.0f, 1.0f}},
        {{w,   -h,   0.0f},  {1.0f, 1.0f, 1.0f}},
        
        {{w,  -h,    0.0f},  {1.0f, 1.0f, 1.0f}},
        {{-w,  h,    0.0f},  {1.0f, 1.0f, 1.0f}},
        {{w,   h,    0.0f},  {1.0f, 1.0f, 1.0f}},
    };
    self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceCPUCacheModeDefaultCache];
    
    uint16_t indices[] = {
        // 索引
        0,  1,  2,
        3,  4,  5,
        6,  7,  8,
        9,  10, 11,
        12, 14, 13,
        15, 16, 17,
    };
    
    self.indexBuffer = [self.device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceCPUCacheModeDefaultCache];
    self.indexBuffer.label = @"Indices";
    self.indexCount = sizeof(indices) / sizeof(uint16_t);
}

- (void)timerAction {
    if (!_mouseDown) {
        _rz += 0.05;
        [self render];
    }
}

- (void)mouseDown:(NSEvent *)event {
    if (event.type == NSEventTypeLeftMouseDown) {
        _mouseDown = YES;
        _downPoint = event.locationInWindow;
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if (_mouseDown && event.type == NSEventTypeLeftMouseDragged) {
        float rz = _rz + (event.locationInWindow.x - _downPoint.x) / 100;
        float rx = _rx + (_downPoint.y - event.locationInWindow.y) / 100;
        _downPoint = event.locationInWindow;
        _rz = rz;
        _rx = rx;
        [self render];
    }
}

- (void)mouseUp:(NSEvent *)event{
    if (event.type == NSEventTypeLeftMouseUp) {
        _mouseDown = NO;
    }
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
        [self setupMatrixWithEncoder:commandEncoder];
        [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:XYVertexInputIndexVertices];
        [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [commandEncoder setCullMode:MTLCullModeBack];
        [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                   indexCount:self.indexCount
                                    indexType:MTLIndexTypeUInt16
                                  indexBuffer:self.indexBuffer
                            indexBufferOffset:0];
        
        [commandEncoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

- (void)setupMatrixWithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder {
    CGSize size = self.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0), aspect, 0.01f, 100.f);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rx, 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rz, 0, 0, 1);
    XYMatrix matrix = {convertMetalMatrixFromGLKMatrix(projectionMatrix), convertMetalMatrixFromGLKMatrix(modelViewMatrix)};
    [renderEncoder setVertexBytes:&matrix
                           length:sizeof(matrix)
                          atIndex:XYVertexInputIndexMatrix];
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

- (void)rotationZ:(float)v {
    _rz = v;
    [self render];
}

- (void)rotationX:(float)v {
    _rx = v;
    [self render];
}

@end

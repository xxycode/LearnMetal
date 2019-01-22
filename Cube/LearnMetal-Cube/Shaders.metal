//
//  Shaders.metal
//  LearnMetal
//
//  Created by XiaoXueYuan on 2019/1/10.
//  Copyright © 2019 xxy. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "XYShaderTypes.h"
typedef struct {
    float4 position [[position]];
    float4 color;
} RasterizerData;

typedef struct
{
    float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
    float2 textureCoordinate; // 纹理坐标，会做插值处理
    float4 color;
} RasterizerDataPP;

struct Uniforms
{
    float4x4 modelViewProjectionMatrix;
};

vertex RasterizerData vertexShader(constant XYVertex *vertices [[buffer(XYVertexInputIndexVertices)]],
                                   uint vid [[vertex_id]]) {
    RasterizerData outVertex;
    
    outVertex.position = vector_float4(vertices[vid].position, 1.0);

    outVertex.color = vertices[vid].color;

    
    
    return outVertex;
}

fragment float4 fragmentShader(RasterizerDataPP inVertex [[stage_in]], texture2d<half> colorTexture [[ texture(0) ]]) {
    return inVertex.color;
}

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
    float2 textureCoordinate;
} RasterizerData;


vertex RasterizerData vertexShader(constant XYVertex *vertices [[buffer(XYVertexInputIndexVertices)]],
                                   constant XYMatrix *matrix [[buffer(XYVertexInputIndexMatrix)]],
                                   uint vid [[vertex_id]]) {
    RasterizerData outVertex;
    
    outVertex.position = matrix->projectionMatrix * matrix->modelViewMatrix  * vector_float4(vertices[vid].position, 1.0);
    outVertex.color = vertices[vid].color;
    
    return outVertex;
}

fragment float4 fragmentShader(RasterizerData inVertex [[stage_in]], texture2d<half> colorTexture [[ texture(0) ]]) {
    return inVertex.color;
}

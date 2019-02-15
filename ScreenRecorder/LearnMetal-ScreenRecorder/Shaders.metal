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
typedef struct
{
    float4 position [[position]];
    float2 texCoords;
    float alpha;
} RasterizerData;

vertex RasterizerData vertexShader(constant XYVertex *vertices [[buffer(XYVertexMainVertices)]],
                                   uint vid [[vertex_id]]) {
    
    RasterizerData outVertex;
    outVertex.position = vector_float4(vertices[vid].position, 0.0, 1.0);
    outVertex.texCoords = vertices[vid].textureCoordinate;
    outVertex.alpha = vertices[vid].alpha;
    return outVertex;
}

fragment float4 fragmentShader(RasterizerData inVertex [[stage_in]],
                               texture2d<float> tex2d [[texture(XYTextureIndexBaseContent)]],
                               sampler samplr [[sampler(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    float4 color = float4(tex2d.sample(textureSampler, inVertex.texCoords));
    return float4(color.rgb, color.a * inVertex.alpha);
}

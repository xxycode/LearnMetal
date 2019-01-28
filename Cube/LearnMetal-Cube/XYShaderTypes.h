//
//  XYShaderTypes.h
//  LearnMetal
//
//  Created by XiaoXueYuan on 2019/1/10.
//  Copyright © 2019 xxy. All rights reserved.
//

#ifndef XYShaderTypes_h
#define XYShaderTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float3 position;
    vector_float4 color;
} XYVertex;

typedef enum XYVertexInputIndex {
    XYVertexInputIndexVertices = 0,
    XYVertexInputIndexMatrix
} XYVertexInputIndex;

typedef struct {
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} XYMatrix;

#endif /* XYShaderTypes_h */

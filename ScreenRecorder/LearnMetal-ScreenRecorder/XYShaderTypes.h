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
    vector_float2 position;
    vector_float2 textureCoordinate;
    float alpha;
} XYVertex;

typedef enum XYTextureIndex {
    XYTextureIndexBaseContent = 0,
    XYTextureIndexMaskContent = 1
} XYTextureIndex;

typedef enum XYVertexInputIndex {
    XYVertexMainVertices = 0,
    XYVertexMaskVertices
} XYVertexInputIndex;
#endif /* XYShaderTypes_h */

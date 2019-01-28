//
//  MatrixTool.c
//  LearnMetal-Cube
//
//  Created by XiaoXueYuan on 2019/1/28.
//  Copyright © 2019 xxy. All rights reserved.
//

#import "MatrixTool.h"

matrix_float4x4 convertMetalMatrixFromGLKMatrix(GLKMatrix4 matrix) {
    matrix_float4x4 ret = (matrix_float4x4){
        simd_make_float4(matrix.m00, matrix.m01, matrix.m02, matrix.m03),
        simd_make_float4(matrix.m10, matrix.m11, matrix.m12, matrix.m13),
        simd_make_float4(matrix.m20, matrix.m21, matrix.m22, matrix.m23),
        simd_make_float4(matrix.m30, matrix.m31, matrix.m32, matrix.m33),
    };
    return ret;
}


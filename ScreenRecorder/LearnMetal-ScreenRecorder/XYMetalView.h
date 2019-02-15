//
//  XYMetalView.h
//  LearnMetal
//
//  Created by XiaoXueYuan on 2019/1/10.
//  Copyright © 2019 xxy. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface XYMetalView : NSView

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer size:(CGSize)size pixelFormat:(MTLPixelFormat)pixelFormat;

@end

NS_ASSUME_NONNULL_END

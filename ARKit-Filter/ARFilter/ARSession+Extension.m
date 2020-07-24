//
//  ARSession+Extension.m
//  
//
//  Created by xu on 2019/4/12.
//  Copyright © 2019 du. All rights reserved.
//

#import "ARSession+Extension.h"
#import "ARKit_Filter-Swift.h"
#import <objc/runtime.h>

@implementation ARSession (Extension)
+ (void)load {
    [ARSession swizzleInstanceMethod:@selector(currentFrame) with:@selector(_currentFrame)];
}

- (ARFrame *)_currentFrame {
    ARFrame *frame =  [self _currentFrame];
    CVPixelBufferRef buffer = frame.capturedImage;
    if (buffer) {
        [ARFilterManager.sharedInstance processWithPixelBuffer:buffer];
    }
    return frame;
}

+ (BOOL)swizzleInstanceMethod:(SEL)originalSel with:(SEL)newSel {
    Method originalMethod = class_getInstanceMethod(self, originalSel);
    Method newMethod = class_getInstanceMethod(self, newSel);
    if (!originalMethod || !newMethod) return NO;
    
    class_addMethod(self,
                    originalSel,
                    class_getMethodImplementation(self, originalSel),
                    method_getTypeEncoding(originalMethod));
    class_addMethod(self,
                    newSel,
                    class_getMethodImplementation(self, newSel),
                    method_getTypeEncoding(newMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(self, originalSel),
                                   class_getInstanceMethod(self, newSel));
    return YES;
}

@end


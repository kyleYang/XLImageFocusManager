//
//  XLFocusUtil.m
//  XLImageFocusManager
//
//  Created by Kyle on 15/5/17.
//  Copyright (c) 2015年 xiaoluuu. All rights reserved.
//

#import "XLFocusUtil.h"

@implementation XLFocusUtil



+ (CGRect)sizeThatFitsInSize:(CGSize)boundingSize initialSize:(CGSize)initialSize
{
    // Compute the final size that fits in boundingSize in order to keep aspect ratio from initialSize.
    CGSize fittingSize;
    CGRect fittingFrame;
    CGFloat widthRatio;
    
    if (initialSize.width < boundingSize.width && initialSize.height < boundingSize.width) {
        
        fittingSize = initialSize;
        fittingFrame = CGRectMake((boundingSize.width-fittingSize.width)/2, (boundingSize.height-fittingSize.height)/2, fittingSize.width, fittingSize.height);
        
        return fittingFrame;
        
    }
    
    widthRatio = boundingSize.width / initialSize.width;
    fittingSize = CGSizeMake(boundingSize.width, floorf(initialSize.height * widthRatio));
    
    CGFloat originY = (boundingSize.height-fittingSize.height)/2;
    
    fittingFrame = CGRectMake((boundingSize.width-fittingSize.width)/2, originY<0?0:originY, fittingSize.width, fittingSize.height);
    return fittingFrame;
    
}

@end

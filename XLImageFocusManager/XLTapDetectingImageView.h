//
//  XLTapDetectingImageView.h
//  XLImageFocusManager
//
//  Created by Kyle on 15/5/17.
//  Copyright (c) 2015年 xiaoluuu. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol XLTapDetectingImageViewDelegate;

@interface XLTapDetectingImageView : UIImageView {}

@property (nonatomic, weak) id <XLTapDetectingImageViewDelegate> tapDelegate;

@end

@protocol XLTapDetectingImageViewDelegate <NSObject>

@optional

- (void)imageView:(XLTapDetectingImageView *)imageView singleTapDetected:(UITouch *)touch;
- (void)imageView:(XLTapDetectingImageView *)imageView doubleTapDetected:(UITouch *)touch;
- (void)imageView:(XLTapDetectingImageView *)imageView tripleTapDetected:(UITouch *)touch;

@end
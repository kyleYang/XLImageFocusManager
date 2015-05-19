//
//  XLZoomImageView.h
//  XLImageFocusManager
//
//  Created by Kyle on 15/5/17.
//  Copyright (c) 2015年 xiaoluuu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XLTapDetectingImageView.h"

@class XLImageFocusController;

@interface XLZoomImageView : UIScrollView

@property (nonatomic, weak) XLImageFocusController *focusController;
@property (nonatomic, readonly) XLTapDetectingImageView *photoImageView;
@property (nonatomic, strong) UIImage *photoImage;
@property (nonatomic, strong) NSString *imageURL;

@property (nonatomic, assign) NSUInteger index;

- (instancetype)initWithFocusController:(XLImageFocusController *)controller;

- (void)displayImage;
- (void)displayImageFailure;
- (void)loadingURL:(NSString *)url;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;

@end

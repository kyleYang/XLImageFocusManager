//
//  XLImageFocusController.h
//  XLImageFocusManager
//
//  Created by Kyle on 15/5/15.
//  Copyright (c) 2015年 xiaoluuu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIImageView+WebCache.h>

@class XLImageScrollView;

@class XLImageFocusController;

@protocol XLImageFocusControllerDelegate <NSObject>

@required
- (NSUInteger)numberOfItemInImageFocusController:(XLImageFocusController *)focusController;
- (UIImage *)thumbImageForFocusController:(XLImageFocusController *)controller atIndex:(NSUInteger)index;
- (void)imageFocusController:(XLImageFocusController *)controller endFocusAtIdex:(NSUInteger)index;

@optional
- (NSUInteger)currentPageOfIndexInImageFocusController:(XLImageFocusController *)focusController;
- (NSString *)imageURLForFocusController:(XLImageFocusController *)controller atindex:(NSUInteger)index;

@end

@interface XLImageFocusController : UIViewController


@property (nonatomic, weak) id<XLImageFocusControllerDelegate> delegate;
@property (nonatomic, readonly) NSUInteger photoCount;
@property (nonatomic, readonly, getter=getCurrentPageIndex) NSUInteger currentPageIndex;

@property (nonatomic, readonly, getter = getFocusImageView) UIImageView *focusImageView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) XLImageScrollView *scrollView;

- (void)reloadData;



- (void)installZoomView;
- (void)uninstallZoomView;
- (void)endFocus;
- (void)updateOrientationAnimated:(BOOL)animation;

@end

//
//  XLImageFocusManager.h
//  XLImageFocusManager
//
//  Created by Kyle on 15/5/15.
//  Copyright (c) 2015年 xiaoluuu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XLImageFocusManager;
@class XLImageFocusController;

@protocol XLImageFocusDelegate <NSObject>

@required


- (UIViewController *)parentViewControllerForImageFocusManager:(XLImageFocusManager *)manager;
- (CGRect)imageFocusManager:(XLImageFocusManager *)manager absoluteFrameWithView:(UIView *)mediaView atIndex:(NSUInteger)index;


@optional
- (NSUInteger)numberOfItemInImageFocusManager:(XLImageFocusManager *)manager;
- (UIImage *)imageFocusManager:(XLImageFocusManager *)manager thumbImageWithView:(UIView *)mediaView atIndex:(NSUInteger)index;
- (NSString *)imageFocusManager:(XLImageFocusManager *)manager originImageURLIndex:(NSUInteger)index;
- (NSString *)imageFocusManager:(XLImageFocusManager *)manager titleForView:(UIView *)view atIndex:(NSUInteger)index;
- (CGRect)imageFocusManagerFinalFrame:(XLImageFocusManager *)mediaFocusManager;
- (UIView *)imageFocusManager:(XLImageFocusManager *)mediaFocusManager viewAtIndex:(NSUInteger)index;

// Called when a focus view is about to be shown. For example, you might use this method to hide the status bar.
- (void)imageFocusManagerWillAppear:(XLImageFocusManager *)manager;
// Called when a focus view has been shown.
- (void)imageFocusManagerDidAppear:(XLImageFocusManager *)manager;
// Called when the view is about to be dismissed by the 'done' button or by gesture. For example, you might use this method to show the status bar (if it was hidden before).
- (void)imageFocusManagerWillDisappear:(XLImageFocusManager *)manager;
// Called when the view has be dismissed by the 'done' button or by gesture.
- (void)imageFocusManagerDidDisappear:(XLImageFocusManager *)manager;
// Called before mediaURLForView to check if image is already on memory.


@end




@interface XLImageFocusManager : NSObject

@property (nonatomic, weak) id<XLImageFocusDelegate> delegate;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, assign) NSTimeInterval anmationDuration;
@property (nonatomic, readonly) XLImageFocusController *focusViewController;



- (void)startFocusView:(UIView *)view;
- (void)startFocusView:(UIView *)view atIndex:(NSUInteger)index;
- (void)endFocus;
- (void)endFocusAtIndex:(NSUInteger)index;

@end

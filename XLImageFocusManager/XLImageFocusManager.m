//
//  XLImageFocusManager.m
//  XLImageFocusManager
//
//  Created by Kyle on 15/5/15.
//  Copyright (c) 2015年 xiaoluuu. All rights reserved.
//

#import "XLImageFocusManager.h"
#import "XLImageFocusController.h"
#import <SDWebImageManager.h>
#import "XLFocusUtil.h"


@interface XLImageFocusManager()<XLImageFocusControllerDelegate>


@property (nonatomic, strong) XLImageFocusController *focusViewController;
@property (nonatomic, strong) UIView *imageView;
@property (nonatomic, assign) NSInteger currentIndex;

@end



@implementation XLImageFocusManager

- (instancetype)init
{
    if (self = [super init]) {
        
        _backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0f];
        _anmationDuration = 0.3;
    }
    
    return self;
}

#pragma mark  --------------------------
#pragma mark public method

- (void)startFocusView:(UIView *)view
{
    [self startFocusView:view atIndex:0];
    
}

- (void)startFocusView:(UIView *)meidaView atIndex:(NSUInteger)index
{
    UIViewController *parentViewController;
    UIView *imageView;
    
    __block CGRect untransformedFinalImageFrame;
    
    
    _focusViewController = [self focusViewControllerForView:meidaView atIndex:index];
    _focusViewController.delegate = self;
    if(_focusViewController == nil)
        return;

    if ([self.delegate respondsToSelector:@selector(imageFocusManagerWillAppear:)])
    {
        [self.delegate imageFocusManagerWillAppear:self];
    }
    
    
    _currentIndex = index;

    parentViewController = [self.delegate parentViewControllerForImageFocusManager:self];
    
    [_focusViewController willMoveToParentViewController:parentViewController];
    [parentViewController addChildViewController:_focusViewController];
    [parentViewController.view addSubview:_focusViewController.view];
    
    
    
    UIImage *animateImage = nil;
    if ([self.delegate respondsToSelector:@selector(imageFocusManager:thumbImageWithView:atIndex:)]) {
        
        animateImage = [self.delegate imageFocusManager:self thumbImageWithView:meidaView atIndex:index];
        
    }
    if ([self.delegate respondsToSelector:@selector(imageFocusManager:originImageURLIndex:)]) {
        NSString *imageURL = [self.delegate imageFocusManager:self originImageURLIndex:index];
        if (imageURL != nil) {
            UIImage *image = [[SDWebImageManager sharedManager].imageCache imageFromDiskCacheForKey:imageURL];
            if (image != nil) {
                animateImage = image;
            }
        }
    }
    _focusViewController.focusImageView.image = animateImage;
    _focusViewController.focusImageView.frame = [self.delegate imageFocusManager:self absoluteFrameWithView:meidaView atIndex:index];
    imageView = _focusViewController.focusImageView;
    
    CGRect boundsSize = [[UIScreen mainScreen] bounds];
    CGSize initSize = CGSizeZero;
    
    if ([self.delegate respondsToSelector:@selector(imageFocusManagerFinalFrame:)]) {
        boundsSize = [self.delegate imageFocusManagerFinalFrame:self];
    }
    
    if (animateImage != nil) {
        initSize = animateImage.size;
    }
    
    CGRect finalFrame = [XLFocusUtil sizeThatFitsInSize:boundsSize.size initialSize:initSize];
    [_focusViewController beginAppearanceTransition:YES animated:YES];
   
    [UIView animateWithDuration:.05
                     animations:^{
                         CGRect frame;
                         CGRect initialFrame;
                         CGAffineTransform initialTransform;
                         
                         _focusViewController.view.backgroundColor = self.backgroundColor;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:_anmationDuration
                                          animations:^{
                                              CGRect frame;
                                              
                                              imageView.frame = finalFrame;
                                          }
                                          completion:^(BOOL finished) {
                                              
                                              
                                              [self installZoomView];
                                              
                                              
                                              if ([self.delegate respondsToSelector:@selector(imageFocusManagerDidAppear:)])
                                              {
                                                  [self.delegate imageFocusManagerDidAppear:self];
                                              }
                                              
                                              [_focusViewController endAppearanceTransition];
                                              [_focusViewController didMoveToParentViewController:parentViewController];
                                              
                                          }];
                     }];
    

    
}

- (void)endFocus
{
    [self endFocusAtIndex:0];
}


- (void)endFocusAtIndex:(NSUInteger)index
{
    NSTimeInterval duration = 0.6;
    UIImageView *contentView;

    [self uninstallZoomView];
    
    contentView = _focusViewController.focusImageView;
    if (contentView == nil)
        return;
    
    [self.focusViewController willMoveToParentViewController:nil];
    [self.focusViewController beginAppearanceTransition:NO animated:YES];
    
    UIImage *animateImage = contentView.image;
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    CGSize initSize = CGSizeZero;
    
    if ([self.delegate respondsToSelector:@selector(imageFocusManagerFinalFrame:)]) {
        bounds = [self.delegate imageFocusManagerFinalFrame:self];
    }
    
    if (animateImage != nil) {
        initSize = animateImage.size;
    }else{
        initSize = bounds.size;
    }
    
    CGRect beginFrame = [XLFocusUtil sizeThatFitsInSize:bounds.size initialSize:initSize];
    CGRect finalFrame = [self.delegate imageFocusManager:self absoluteFrameWithView:nil atIndex:index];
    
    UIView *anmiationView = nil;
    
    if ([self.delegate respondsToSelector:@selector(imageFocusManager:viewAtIndex:)]) {
        
        anmiationView = [self.delegate imageFocusManager:self viewAtIndex:index];
    }
    
    contentView.frame = beginFrame;
    
    
    BOOL isVisiable = FALSE;
    
    if (CGRectIntersectsRect(bounds, finalFrame)) {
        isVisiable = TRUE;
        anmiationView.hidden = TRUE;
    }
    
    
    
    [UIView animateWithDuration:_anmationDuration
                     animations:^{
                         if (self.delegate && [self.delegate respondsToSelector:@selector(imageFocusManagerWillDisappear:)])
                         {
                             [self.delegate imageFocusManagerWillDisappear:self];
                         }
                         
//                         _focusViewController.focusImageView.transform = CGAffineTransformIdentity;
                         
                         if (isVisiable) {
                             
                             contentView.frame = finalFrame;
                             
                         }else{
                             
                             CGRect scalFrame;
                             scalFrame.size.width= beginFrame.size.width * 4;
                             scalFrame.size.height = beginFrame.size.height * 4;
                             scalFrame.origin.x = ( bounds.size.width - scalFrame.size.width )/2;
                             scalFrame.origin.y = ( bounds.size.height - scalFrame.size.height )/2;
                             contentView.frame = scalFrame;
                             contentView.alpha = .4;
                         }
                         
                        self.focusViewController.view.backgroundColor = [UIColor clearColor];
                         
                     }
                     completion:^(BOOL finished) {
                         
                         anmiationView.hidden = FALSE;
                         
                         [self.focusViewController endAppearanceTransition];
                         [self.focusViewController.view removeFromSuperview];
                         [self.focusViewController removeFromParentViewController];
                         [self.focusViewController didMoveToParentViewController:nil];
                         self.focusViewController = nil;
                         
                         
                         if (self.delegate && [self.delegate respondsToSelector:@selector(imageFocusManagerDidDisappear:)])
                         {
                             [self.delegate imageFocusManagerDidDisappear:self];
                         }
                     }];
    
}



#pragma mark -----
#pragma mark XLImageFocusControllerDelegate

- (NSUInteger)numberOfItemInImageFocusController:(XLImageFocusController *)focusController
{
    NSUInteger defaultCount = 1;
    
    if ([self.delegate respondsToSelector:@selector(numberOfItemInImageFocusManager:)]) {
        
        return [self.delegate numberOfItemInImageFocusManager:self];
    }
    
    return defaultCount;
}


- (NSUInteger)currentPageOfIndexInImageFocusController:(XLImageFocusController *)focusController
{
    return _currentIndex;
}


- (UIImage *)thumbImageForFocusController:(XLImageFocusController *)controller atIndex:(NSUInteger)index
{
    
    if ([self.delegate respondsToSelector:@selector(imageFocusManager:originImageURLIndex:)]) {
        
        NSString *imageURL = [self.delegate imageFocusManager:self originImageURLIndex:index];
        UIImage *image = [[SDWebImageManager sharedManager].imageCache imageFromDiskCacheForKey:imageURL];
        if (image != nil) {
            return image;
        }

    }
    
    
    if ([self.delegate respondsToSelector:@selector(imageFocusManager:thumbImageWithView:atIndex:)]) {
        
        UIImage *image = [self.delegate imageFocusManager:self thumbImageWithView:nil atIndex:index];
        if (image != nil) {
            return image;
        }
        
    }
    return nil;
}


- (NSString *)imageURLForFocusController:(XLImageFocusController *)controller atindex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(imageFocusManager:originImageURLIndex:)]) {
        
        NSString *imageURL = [self.delegate imageFocusManager:self originImageURLIndex:index];
        return imageURL;
    }

    return @"";
    
}



- (void)imageFocusController:(XLImageFocusController *)controller endFocusAtIdex:(NSUInteger)index
{
    [self endFocusAtIndex:index];
}

#pragma mark -------------------------------
#pragma mark private method




- (void)installZoomView
{
    [_focusViewController installZoomView];
    
}


-(void)uninstallZoomView
{
    [_focusViewController uninstallZoomView];
}


- (XLImageFocusController *)focusViewControllerForView:(UIView *)mediaView atIndex:(NSUInteger)index
{
    XLImageFocusController *viewController;
    
    viewController = [[XLImageFocusController alloc] initWithNibName:nil bundle:nil];
    [self installDefocusActionOnFocusViewController:viewController];
    
    return viewController;
}




- (void)installDefocusActionOnFocusViewController:(XLImageFocusController *)viewController
{
    
}



@end

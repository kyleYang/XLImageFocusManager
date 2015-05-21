//
//  XLImageFocusController.m
//  XLImageFocusManager
//
//  Created by Kyle on 15/5/15.
//  Copyright (c) 2015年 xiaoluuu. All rights reserved.
//

#import "XLImageFocusController.h"
#import "XLZoomImageView.h"

#define PADDING                  10

static NSTimeInterval const kDefaultOrientationAnimationDuration = 0.4;

@interface XLImageFocusController ()<UIScrollViewDelegate>
{
    // Paging & layout
    NSMutableSet *_visiblePages, *_recycledPages;
    NSUInteger _currentPageIndex;
    NSUInteger _previousPageIndex;
    
    CGRect _previousLayoutBounds;
    NSUInteger _pageIndexBeforeRotation;
    BOOL _rotating;
}

@property (nonatomic, assign) NSUInteger photoCount;
@property (nonatomic, assign) NSUInteger currentPageIndex;

@property (nonatomic, strong) UIImageView *focusImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *pagingScrollView;

@property (nonatomic, assign) UIDeviceOrientation previousOrientation;

@end

@implementation XLImageFocusController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        _photoCount = NSNotFound; // default phont count is NSNotFound;
        
        _visiblePages = [[NSMutableSet alloc] init];
        _recycledPages = [[NSMutableSet alloc] init];
        
         _previousLayoutBounds = CGRectZero;
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}






#pragma mark ------
#pragma mark Public

- (void)reloadData
{
  
    _photoCount = NSNotFound;
    
    // Get data
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    NSUInteger pageIndex = [self delegateCurrentPageIndex];
    
    // Update layout
    if ([self isViewLoaded]) {
        while (_pagingScrollView.subviews.count) {
            [[_pagingScrollView.subviews lastObject] removeFromSuperview];
        }
        [self.view setNeedsLayout];
    }

}


- (void)installZoomView
{
    if (!_pagingScrollView) {
        
        CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
        _pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
        _pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _pagingScrollView.pagingEnabled = YES;
        _pagingScrollView.delegate = self;
        _pagingScrollView.showsHorizontalScrollIndicator = NO;
        _pagingScrollView.showsVerticalScrollIndicator = NO;
        _pagingScrollView.backgroundColor = [UIColor blackColor];
        _pagingScrollView.contentOffset = CGPointMake(CGFLOAT_MIN, 0);
        _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];

    }
    _pagingScrollView.hidden = FALSE;
    _focusImageView.hidden = TRUE;
    [self.view addSubview:_pagingScrollView];
    
    NSUInteger index = [self delegateCurrentPageIndex];
    
    [_pagingScrollView setContentOffset:[self contentOffsetForPageAtIndex:index] animated:FALSE];
    [self tilePages];
    
    XLZoomImageView *pageView = [self getVisiablePageViewAtIndex:index];
    pageView.photoImage = _focusImageView.image;
    
    [self didStartViewingPageAtIndex:index];
    
    
    
}

- (void)uninstallZoomView
{
    
    _pagingScrollView.hidden = YES;
    _focusImageView.hidden = NO;
    _focusImageView.image = [self getVisiablePageViewAtIndex:_currentPageIndex].photoImageView.image;
    
}


- (void)endFocus
{
    [self.delegate imageFocusController:self endFocusAtIdex:_currentPageIndex];
}

#pragma mark ----
#pragma mark Priviate


- (NSUInteger)numberOfPhotos {
    
    if (_photoCount == NSNotFound && [_delegate respondsToSelector:@selector(numberOfItemInImageFocusController:)]) {
        _photoCount = [_delegate numberOfItemInImageFocusController:self];
    }
    if (_photoCount == NSNotFound) _photoCount = 0;
    return _photoCount;
}


- (NSUInteger)delegateCurrentPageIndex
{
    if ([_delegate respondsToSelector:@selector(currentPageOfIndexInImageFocusController:)]) {
        _currentPageIndex = [_delegate currentPageOfIndexInImageFocusController:self];
    }
    return _currentPageIndex;
}


- (NSUInteger)getCurrentPageIndex
{
    return _currentPageIndex;
}


#pragma mark - Frame Calculations

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}



- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat newOffset = index * pageWidth;
    return CGPointMake(newOffset, 0);
}


- (XLZoomImageView *)getVisiablePageViewAtIndex:(NSUInteger)index
{
    for (XLZoomImageView *page in _visiblePages) {
        if(index == page.index){
            return page;
        }
    }
    return nil;
}


#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutVisiblePages];
}

- (void)layoutVisiblePages {
    

    
    // Remember index
    NSUInteger indexPriorToLayout = _currentPageIndex;
    
    // Get paging scroll view frame to determine if anything needs changing
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    // Recalculate contentSize based on current orientation
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // Adjust frames and configuration of each visible page
    for (XLZoomImageView *page in _visiblePages) {
        NSUInteger index = page.index;
        page.frame = [self frameForPageAtIndex:index];
               // Adjust scales if bounds has changed since last time
        if (!CGRectEqualToRect(_previousLayoutBounds, self.view.bounds)) {
            // Update zooms for new bounds
            [page setMaxMinZoomScalesForCurrentBounds];
            _previousLayoutBounds = self.view.bounds;
        }
        
    }
    
    // Adjust contentOffset to preserve page location based on values collected prior to location
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
    _currentPageIndex = indexPriorToLayout;

    
}



- (void)tilePages
{
    
    // Calculate which pages should be visible
    // Ignore padding as paging bounces encroach on that
    // and lead to false page loads
    
    CGFloat width = _pagingScrollView.frame.size.width;
    NSInteger page = (_pagingScrollView.contentOffset.x + (0.5f * width)) / width;
    
    NSInteger iFirstIndex = page -1;;
    NSInteger iLastIndex  = page+1;
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
    
    // Recycle no longer needed pages
    NSInteger pageIndex;
    for (XLZoomImageView *page in _visiblePages) {
        pageIndex = page.index;
        if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
            [_recycledPages addObject:page];
            [page prepareForReuse];
            [page removeFromSuperview];
    
        }
    }
    
    [_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
    
    // Add missing pages
    for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            
            // Add new page
            XLZoomImageView *page = [self dequeueRecycledPage];
            if (!page) {
                page = [[XLZoomImageView alloc] initWithFocusController:self];
            }
            [_visiblePages addObject:page];
            [self configurePage:page forIndex:index];
            
            [_pagingScrollView addSubview:page];
            
            page.photoImage = [self.delegate thumbImageForFocusController:self atIndex:index];
            page.imageURL = [self.delegate imageURLForFocusController:self atindex:index];
            
        }
    }
    
}

- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    
    XLZoomImageView *page = [self getVisiablePageViewAtIndex:index];
    [page loadingURL:[self.delegate imageURLForFocusController:self atindex:index]];
}




- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    for (XLZoomImageView *page in _visiblePages)
    {
        if (page.index == index) {
            return YES;
        }
    }
    return NO;
}


- (XLZoomImageView *)dequeueRecycledPage {
    XLZoomImageView *page = [_recycledPages anyObject];
    if (page) {
        [_recycledPages removeObject:page];
    }
    return page;
}


- (void)configurePage:(XLZoomImageView *)page forIndex:(NSUInteger)index {
    page.frame = [self frameForPageAtIndex:index];
    page.index = index;
    
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return CGRectIntegral(pageFrame);
}

- (void)loadingCurrentPageOriginImage
{
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger index = (NSInteger)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
    if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
    NSUInteger previousCurrentPage = _currentPageIndex;
    _currentPageIndex = index;
    if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];
    }

    
}

#pragma mark -----
#pragma mark property


- (UIImageView *)getFocusImageView
{
    if (_focusImageView != nil) {
        
        return _focusImageView;
    }
    
    _focusImageView = [[UIImageView alloc] init];
    [self.view addSubview:_focusImageView];
    return _focusImageView;
}

#pragma mark -----
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // Checks
    
    
    // Tile pages
    [self tilePages];
    
    // Calculate current page
    
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadingCurrentPageOriginImage];
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)isParentSupportingInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    switch(toInterfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskPortrait;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskPortraitUpsideDown;
            
        case UIInterfaceOrientationLandscapeLeft:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskLandscapeLeft;
            
        case UIInterfaceOrientationLandscapeRight:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskLandscapeRight;
            
        case UIInterfaceOrientationUnknown:
            return YES;
    }
}


- (void)updateOrientationAnimated:(BOOL)animated
{
    CGAffineTransform transform;
    CGRect frame;
    NSTimeInterval duration = kDefaultOrientationAnimationDuration;
    
    if([UIDevice currentDevice].orientation == self.previousOrientation)
        return;
    
    if((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && UIDeviceOrientationIsLandscape(self.previousOrientation))
       || (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation) && UIDeviceOrientationIsPortrait(self.previousOrientation)))
    {
        duration *= 2;
    }
    
    if(([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait)
       || [self isParentSupportingInterfaceOrientation:[UIDevice currentDevice].orientation])
    {
        transform = CGAffineTransformIdentity;
    }
    else
    {
        switch ([UIDevice currentDevice].orientation)
        {
            case UIDeviceOrientationLandscapeRight:
                if(self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait)
                {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                else
                {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                break;
                
            case UIDeviceOrientationLandscapeLeft:
                if(self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait)
                {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                else
                {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                break;
                
            case UIDeviceOrientationPortrait:
                transform = CGAffineTransformIdentity;
                break;
                
            case UIDeviceOrientationPortraitUpsideDown:
                transform = CGAffineTransformMakeRotation(M_PI);
                break;
                
            case UIDeviceOrientationFaceDown:
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationUnknown:
                return;
        }
    }
    
    if(animated)
    {
        frame = self.focusImageView.frame;
        [UIView animateWithDuration:duration
                         animations:^{
                             self.focusImageView.transform = transform;
                             self.focusImageView.frame = frame;
                         }];
    }
    else
    {
        frame = self.focusImageView.frame;
        self.focusImageView.transform = transform;
        self.focusImageView.frame = frame;
    }
    self.previousOrientation = [UIDevice currentDevice].orientation;
}



- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    // Remember page index before rotation
    _pageIndexBeforeRotation = _currentPageIndex;
    _rotating = YES;
    
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    // Perform layout
    _currentPageIndex = _pageIndexBeforeRotation;
    
    
    // Layout
    [self layoutVisiblePages];
    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    _rotating = NO;
    // Ensure nav bar isn't re-displayed
}




#pragma mark - Notifications
- (void)orientationDidChangeNotification:(NSNotification *)notification
{
    [self updateOrientationAnimated:YES];
}
@end

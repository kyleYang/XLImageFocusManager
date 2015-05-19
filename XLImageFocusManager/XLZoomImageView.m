//
//  XLZoomImageView.m
//  XLImageFocusManager
//
//  Created by Kyle on 15/5/17.
//  Copyright (c) 2015年 xiaoluuu. All rights reserved.
//

#import "XLZoomImageView.h"
#import "XLImageFocusController.h"
#import <UIImageView+Webcache.h>
#import <SDWebImageDownloader.h>
#import <SDWebImageDownloaderOperation.h>
#import <DALabeledCircularProgressView.h>
#import "XLFocusUtil.h"
#import "XLImageFocusController.h"

#define XLIMAGE_PROGRESS_NOTIFICATION @"XLIMAGE_PROGRESS_NOTIFICATION"

@interface  XLZoomImageView ()<UIScrollViewDelegate,XLTapDetectingImageViewDelegate>

@property (nonatomic, strong) XLTapDetectingImageView *photoImageView;
@property (nonatomic, strong) DALabeledCircularProgressView *loadingIndicator;

@property (nonatomic, strong) SDWebImageDownloaderOperation *preLoadingOpreation;
@property (nonatomic, assign) BOOL resizeAnimation;

@end



@implementation XLZoomImageView

- (instancetype)initWithFocusController:(XLImageFocusController *)controller
{
    if ((self = [super init])) {
        
        // Setup
        _index = NSUIntegerMax;
        _focusController = controller;
        
        
        
        // Image view
        _photoImageView = [[XLTapDetectingImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.tapDelegate = self;
        _photoImageView.clipsToBounds = YES;
        //        _photoImageView.contentMode = UIViewContentModeCenter;
        _photoImageView.backgroundColor = [UIColor blackColor];
        [self addSubview:_photoImageView];
        
        // Loading indicator
        _loadingIndicator = [[DALabeledCircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 80.0f, 80.0f)];
        _loadingIndicator.userInteractionEnabled = NO;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")) {
            _loadingIndicator.thicknessRatio = 0.1;
            _loadingIndicator.roundedCorners = NO;
        } else {
            _loadingIndicator.thicknessRatio = 0.2;
            _loadingIndicator.roundedCorners = YES;
        }
        _loadingIndicator.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.4];
        _loadingIndicator.layer.cornerRadius = 2.0f;
        _loadingIndicator.progressLabel.textColor = [UIColor whiteColor];
        _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_loadingIndicator];
        
        
        
        // Setup
        self.backgroundColor = [UIColor blackColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    
    
    _photoImageView.image = nil;
    _index = NSUIntegerMax;
}

#pragma mark - Image

- (void)setPhotoImage:(UIImage *)photoImage
{
    
    if (_photoImage == photoImage) {
        return;
    }
    _loadingIndicator.hidden = TRUE;
    _photoImage = photoImage;
    
    if (_photoImage) {
        [self displayImage];
    }
    
}



- (void)setImageURL:(NSString *)imageURL
{
    
    
    if (_imageURL == imageURL) {
         _loadingIndicator.hidden = TRUE;
        _resizeAnimation = FALSE;
        
        return;
        
    }
    
    if (![_preLoadingOpreation isCancelled]) {
        [_preLoadingOpreation cancel];
    }
    
    _imageURL = imageURL;
    [self startLoadingURL:_imageURL withAnimation:FALSE];
    _loadingIndicator.hidden = TRUE;
    
    
}


- (void)loadingURL:(NSString *)url
{
    
    if (url.length < 3) {
        return;
    }
    
    
    UIImage *image = [[SDWebImageManager sharedManager].imageCache imageFromDiskCacheForKey:url];
    if (image != nil) {
        _imageURL = url;
        _loadingIndicator.hidden = TRUE;
        self.photoImage = image;
        return;
    }
    
    
    if (_imageURL == url) {
        
        _resizeAnimation = TRUE;
        _loadingIndicator.hidden = FALSE;
        
        
        return;
        
    }
    
    
    if (![_preLoadingOpreation isCancelled]) {
        [_preLoadingOpreation cancel];
    }
    
    _imageURL = url;
    
    
    
    _loadingIndicator.hidden = FALSE;
    _loadingIndicator.progress = 0;
    _loadingIndicator.progressLabel.text = @"0 %%";
    [self startLoadingURL:_imageURL withAnimation:YES];
    
}




- (void)startLoadingURL:(NSString *)url withAnimation:(BOOL)animation
{
    
    
    typeof(self)  __weak weakSelf = self;
    _resizeAnimation = animation;
    
   _preLoadingOpreation =  [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:_imageURL] options:SDWebImageDownloaderLowPriority|SDWebImageDownloaderProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
        
        CGFloat progress = (CGFloat)receivedSize/(CGFloat)expectedSize;
        _loadingIndicator.progress = progress;
        _loadingIndicator.progressLabel.text = [NSString stringWithFormat:@"%ld %%",(NSInteger)(progress*100)];
        
    } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
       
        if (image != nil && finished) {
             _loadingIndicator.hidden = TRUE;
            [[SDWebImageManager sharedManager].imageCache storeImage:image forKey:_imageURL];
            
            if (_resizeAnimation) {
                 CGRect bounds = [[UIScreen mainScreen] bounds];
                 CGRect beginFrame = [XLFocusUtil sizeThatFitsInSize:bounds.size initialSize:image.size];
                
                [UIView animateWithDuration:.1 animations:^{
                    _photoImageView.image = image;
                    _photoImageView.frame = beginFrame;
                    
                } completion:^(BOOL finished) {
                     weakSelf.photoImage = image;
                    
                }];
                
                
            }else{
               weakSelf.photoImage = image;
            }
            
           
        }
        
        if (finished) {
             _loadingIndicator.hidden = TRUE;
        }
        
        if (error != nil) {
             _loadingIndicator.hidden = TRUE;
        }
        
        
    }];
    
}



// Get and display image
- (void)displayImage {
    
    
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    self.contentSize = CGSizeMake(0, 0);
    
    // Get image from browser as it handles ordering of fetching
    UIImage *img = _photoImage;
    if (img) {
        
        // Hide indicator
        
        
        // Set image
        _photoImageView.image = img;
        _photoImageView.hidden = NO;
        
        // Setup photo frame
        CGRect photoImageViewFrame;
        photoImageViewFrame.origin = CGPointZero;
        photoImageViewFrame.size = img.size;
        _photoImageView.frame = photoImageViewFrame;
        self.contentSize = photoImageViewFrame.size;
        
        
        // Set zoom to minimum zoom
        [self setMaxMinZoomScalesForCurrentBounds];
        
    }
    [self setNeedsLayout];
}




#pragma mark - Loading Progress

#pragma mark - Setup

- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (_photoImageView) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        
        if (xScale > 1 && yScale >1) {
            zoomScale = 1;
        }else{
            zoomScale = xScale;
        }
        
        
    }
    return zoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    // Bail if no image
    if (_photoImageView.image == nil) return;
    
    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // Image is smaller than screen so no zooming!
    if (xScale >= 1 && yScale >= 1) {
        minScale = 1.0;
    }
    
    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScale];
    
    // If we're zooming to fill then centralise
    if (self.zoomScale != minScale) {
        // Centralise
        self.contentOffset = CGPointMake((imageSize.width * self.zoomScale - boundsSize.width) / 2.0,
                                         (imageSize.height * self.zoomScale - boundsSize.height) / 2.0);
        // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
        self.scrollEnabled = NO;
    }
    
    // Layout
    [self setNeedsLayout];
    
    
}

#pragma mark - Layout

- (void)layoutSubviews {
    
    
    // Super
    [super layoutSubviews];
    
    _loadingIndicator.frame = CGRectMake(floorf((self.bounds.size.width - _loadingIndicator.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - _loadingIndicator.frame.size.height) / 2),
                                         _loadingIndicator.frame.size.width,
                                         _loadingIndicator.frame.size.height);
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
        _photoImageView.frame = frameToCenter;
    
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
    
    [_focusController endFocus];
    
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    
    // Cancel any single tap handling
    
    
    // Zoom
    if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {
        
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
        
    } else {
        
        // Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        
    }
    
    
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch {
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleSingleTap:CGPointMake(touchX, touchY)];
}
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleDoubleTap:CGPointMake(touchX, touchY)];
}


@end

//
//  ViewController.m
//  XLImageFocusManager
//
//  Created by Kyle on 15/5/14.
//  Copyright (c) 2015年 xiaoluuu. All rights reserved.
//

#import "ViewController.h"
#import "XLImageFocusManager.h"

@interface ViewController ()<XLImageFocusDelegate>


@property (nonatomic, strong) XLImageFocusManager *focusManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.imageOne addGestureRecognizer:[self getTapGesutre]];
    self.imageOne.userInteractionEnabled = YES;
    
    
    [self.imageTwo addGestureRecognizer:[self getTapGesutre]];
    self.imageTwo.userInteractionEnabled = YES;
    
    [self.imageThree addGestureRecognizer:[self getTapGesutre]];
    self.imageThree.userInteractionEnabled = YES;
    
    
    [self.imageFour addGestureRecognizer:[self getTapGesutre]];
    self.imageFour.userInteractionEnabled = YES;
    
}


#pragma mark
#pragma mark porperty

- (XLImageFocusManager *)focusManager
{
    if (_focusManager == nil) {
        _focusManager = [[XLImageFocusManager alloc] init];
        _focusManager.delegate = self;
    }
    
    return _focusManager;
}


- (UITapGestureRecognizer *)getTapGesutre
{
   return [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    
}

- (void)tapAction:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.view == self.imageOne) {
        
        [self.focusManager startFocusView:self.imageOne atIndex:0];
        
    }else if(gestureRecognizer.view == self.imageTwo){
         [self.focusManager startFocusView:self.imageOne atIndex:1];
    }else if(gestureRecognizer.view == self.imageThree){
        [self.focusManager startFocusView:self.imageOne atIndex:2];
    }else if(gestureRecognizer.view == self.imageFour){
        [self.focusManager startFocusView:self.imageOne atIndex:3];
    }
    
}

#pragma mark
#pragma mark XLImageFocusDelegate

- (NSUInteger)numberOfItemInImageFocusManager:(XLImageFocusManager *)manager
{
    return 4;
}


- (UIViewController *)parentViewControllerForImageFocusManager:(XLImageFocusManager *)manager
{
    return self;
}

- (CGRect)imageFocusManager:(XLImageFocusManager *)manager absoluteFrameWithView:(UIView *)mediaView atIndex:(NSUInteger)index
{
    if (index == 0) {
        return  self.imageOne.frame;;
    }else if(index == 1){
        return  self.imageTwo.frame;;
    }else if(index == 2){
        return  self.imageThree.frame;;
    }else if(index == 3){
        return  self.imageFour.frame;;
    };

    return self.imageOne.frame;
}

- (UIImage *)imageFocusManager:(XLImageFocusManager *)manager thumbImageWithView:(UIView *)mediaView atIndex:(NSUInteger)index
{
    if (index == 0) {
        return [UIImage imageNamed:@"photo1.jpg"];
    }else if(index == 1){
        return [UIImage imageNamed:@"photo2.jpg"];
    }else if(index == 2){
        return [UIImage imageNamed:@"photo3.jpg"];
    }else if(index == 3){
        return [UIImage imageNamed:@"photo4.jpg"];
    };
    
    return nil;
}


- (NSString *)imageFocusManager:(XLImageFocusManager *)manager originImageURLIndex:(NSUInteger)index
{
    if (index == 0) {
        return @"http://pic1.win4000.com/pic/a/1f/74b2466608.jpg";
    }else if(index == 1){
        return @"http://www.netbian.com/d/file/20120525/361c35cb08703aafbb19677afb8e282d.jpg";
    }else if(index == 2){
        return @"http://www.bz55.com/uploads/allimg/140321/1-140321113R6.jpg";
    }else if(index == 3){
        return @"http://www.tupianworld.cn/pic_201101/201112023004620admin212753.jpg";
    };

    return @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

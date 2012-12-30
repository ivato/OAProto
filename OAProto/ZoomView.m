//
//  ZoomView.m
//  OAProto
//
//  Created by Ivan Touzeau on 04/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "ZoomView.h"
#import "EditViewController.h"
#import "UIImage+Resize.h"
#import "OpenAnnotation.h"
#import "OAShape.h"
#import <QuartzCore/QuartzCore.h>

#define USE_ASYNC

@interface ZoomView()
{
    EditViewController      * controller;
    CALayer                 * zoomLayer;
    CAShapeLayer            * compositeLayer;
    CALayer                 * hLayer;
    CALayer                 * vLayer;
}

@property (nonatomic,assign)        EditViewController      * controller;
@property (nonatomic,assign)        CALayer                 * zoomLayer;
@property (nonatomic,assign)        CAShapeLayer            * compositeLayer;

@property (nonatomic,assign)        CALayer                 * hLayer;
@property (nonatomic,assign)        CALayer                 * vLayer;

@end

@implementation ZoomView

@synthesize controller,zoomLayer,compositeLayer,hLayer,vLayer;

-(void) updateZoomForScrollView:(UIScrollView *)scrollView
{
    CGSize contentSize = scrollView.contentSize;
    CGPoint offset = scrollView.contentOffset;
    CGRect zoomRect = CGRectZero;
    CGFloat opacity = 0.0f;
    CGFloat crossOpacity = 0.0f;
    
    if ( CGSizeEqualToSize(contentSize, CGSizeZero)) {
        
        zoomRect = self.bounds;
        
    } else {
        
        zoomRect.origin.x = (offset.x / contentSize.width)*self.frame.size.width;
        zoomRect.origin.y = (offset.y / contentSize.height)*self.frame.size.height;
        zoomRect.size.width = scrollView.frame.size.width/contentSize.width*self.frame.size.width;
        zoomRect.size.height = scrollView.frame.size.height/contentSize.height*self.frame.size.height;
        zoomRect = CGRectIntersection(zoomRect, self.bounds);
        
        opacity = CGRectEqualToRect(zoomRect,self.bounds) ? 0.0f : 1.0f;
        crossOpacity = (zoomRect.size.width < 6 || zoomRect.size.height < 6) ? 1.0f : 0.0f;
        
    }
    zoomLayer.opacity = opacity;
    hLayer.opacity = vLayer.opacity = crossOpacity;
    //[CATransaction begin];
    //[CATransaction setDisableActions:YES];
    zoomLayer.frame = zoomRect;
    hLayer.position = CGPointMake(self.frame.size.width/2,zoomRect.origin.y+zoomRect.size.height/2);
    vLayer.position = CGPointMake(zoomRect.origin.x+zoomRect.size.width/2,self.frame.size.height/2);
    //[CATransaction commit];
}

- (id) initWithEditController:(EditViewController *)aController
{
    CGSize size = aController.image.size;
    if ( size.width>size.height){
        size.width = 200;
        size.height = 200/aController.image.size.width*aController.image.size.height;
    } else {
        size.height = 200;
        size.width = 200/aController.image.size.height*aController.image.size.width;
    }
    CGRect myFrame = CGRectMake(aController.view.frame.size.width-size.width,44,size.width,size.height);
    if ( self = [super initWithFrame:myFrame]){
        
        self->controller = aController;
        
#ifdef USE_ASYNC
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
#endif
            //UIImage * zoomedImage = [aController.resizedImage resizedImage:size interpolationQuality:kCGInterpolationLow];
            UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
            [aController.resizedImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
            UIImage * zoomedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            
#ifdef USE_ASYNC
            dispatch_sync(dispatch_get_main_queue(), ^{
#endif
                [self setImage:zoomedImage];
                
                self.layer.borderColor = [UIColor grayColor].CGColor;
                self.layer.borderWidth = 2.0f;
                
                self.layer.shadowColor      = [UIColor blackColor].CGColor;
                self.layer.shadowOffset     = CGSizeMake(-4, 4);
                self.layer.shadowRadius     = 8.0f;
                self.layer.shadowOpacity    = 0.5f;
                
                self.compositeLayer = [CAShapeLayer layer];
                compositeLayer.fillColor = [UIColor colorWithWhite:1.0f alpha:0.5].CGColor;
                compositeLayer.strokeColor = [UIColor whiteColor].CGColor;
                
                self.hLayer = [CALayer layer];
                self.vLayer = [CALayer layer];
                hLayer.bounds = CGRectMake(0,0,self.bounds.size.width,1);
                vLayer.bounds = CGRectMake(0,0,1,self.bounds.size.height);
                hLayer.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f].CGColor;
                vLayer.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f].CGColor;
                hLayer.opacity = 0.0f;
                vLayer.opacity = 0.0f;
                [self.layer addSublayer:hLayer];
                [self.layer addSublayer:vLayer];
                
                [self.layer addSublayer:compositeLayer];
                
                self.zoomLayer = [CALayer layer];
                zoomLayer.opacity      = 0.0f;
                zoomLayer.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.1f].CGColor;
                zoomLayer.borderColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f].CGColor;
                zoomLayer.borderWidth = 1.0f;
                zoomLayer.bounds = self.bounds;
                [self.layer addSublayer:zoomLayer];
                
                self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;

#ifdef USE_ASYNC
            });
            [pool release];
        });
#endif

    }
    return self;
}

- (void) updateCompositeForNote:(OpenAnnotation *)note
{
    if ( note == nil || self.controller.mode == kDisplayModeNotesThumbnails ){
        self.compositeLayer.path = NULL;
    } else {
        float scale = self.frame.size.width/self.controller.image.size.width / SCALE_RATIO;
        CGAffineTransform t = CGAffineTransformMakeScale(scale, scale);
        CGPathRef compositePath = [note newCompositePath];
        CGPathRef finalPath = CGPathCreateCopyByTransformingPath(compositePath, &t);
        self.compositeLayer.path = finalPath; //path;
        CGPathRelease(compositePath);
        CGPathRelease(finalPath);
    }
}

- (void) updateZoom:(CGRect)rect
{
    zoomLayer.bounds = rect;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


@end

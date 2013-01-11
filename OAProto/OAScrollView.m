//
//  OAScrollView.m
//  OAProto
//
//  Created by Ivan Touzeau on 15/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "OAScrollView.h"
#import <QuartzCore/QuartzCore.h>
#import "OpenAnnotation.h"
#import "OAShape.h"
#import "EditViewController.h"

#import "UIImage+Resize.h"

@interface OAScrollView ()
{
    NSOperationQueue            * hiresOperationQueue;
}

@property (nonatomic,retain)    UIImageView                 * imageView;

@property (nonatomic,assign)    EditViewController          * editController;

@property (nonatomic,assign)    UITouch                     * currentTouch;
@property (nonatomic,retain)    NSMutableSet                * currentTouches;

@property (nonatomic,assign)    OAShape                     * touchedShape;

@property (nonatomic,assign)    CALayer                     * hiLayer;
@property (nonatomic,retain)    NSOperationQueue            * hiresOperationQueue;

@end

@implementation OAScrollView
{
    
    CGSize                      previousContentSize;
    CGSize                      previousBoundsSize;
    CGFloat                     previousZoomScale;
    BOOL                        hasDelayedAction;
    
    uint                        operationId;
    
    /*
        touch delayed actions will need to know touch position and scale values
        We store these values at the touch time, so delayed touch action can process them.
     
     */
    
    CALayer                   * hiLayer;
    
    int                         selectedPointIndex;
    
    CFAbsoluteTime              lastTouchTime;
    
    dispatch_queue_t            hrQueue;
    
}

@synthesize hiresOperationQueue;
@synthesize imageView=_backgroundImageView,hiLayer;
@synthesize currentTouch,currentTouches,touchedShape;

@synthesize thumbnailsLayer, shapesLayer;


#pragma mark - UIView lifecycle

- (id) initWithFrame:(CGRect)frame editController:(EditViewController *)controller
{
    self = [super initWithFrame:frame];
    
    if ( self ){
        
        operationId = 0;
        hrQueue = dispatch_queue_create("hiresqueue", DISPATCH_QUEUE_SERIAL);
        
        hiresOperationQueue = [[NSOperationQueue alloc] init];
        
        [self setDecelerationRate:UIScrollViewDecelerationRateFast];
        [self setDelegate:self];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setContentInset:UIEdgeInsetsMake(IMAGE_MARGIN, IMAGE_MARGIN, IMAGE_MARGIN, IMAGE_MARGIN)];
        [self setMaximumZoomScale:5.0f];
        [self setMinimumZoomScale:0.01f];
        [self setShowsHorizontalScrollIndicator:NO];
        [self setShowsVerticalScrollIndicator:NO];
        
        [self setEditController:controller];
        
        [self setThumbnailsLayer:[CALayer layer]];
        [self setShapesLayer:[CALayer layer]];
        
        for ( OpenAnnotation * note in self.editController.notes ){
            [self.thumbnailsLayer addSublayer:note.thumbnailLayer];
        };
        
        NSMutableSet * ct = [[NSMutableSet alloc] init];
        [self setCurrentTouches:ct];
        [ct release];

        UIImageView * bgimg = [[UIImageView alloc] initWithImage:self.editController.resizedImage];
        bgimg.frame = CGRectMake(0,0,self.editController.image.size.width,self.editController.image.size.height);
        [self setImageView:bgimg];
        [bgimg release];
        [self addSubview:[self imageView]];
        
        [self setContentSize:self.imageView.frame.size];
        
        self.hiLayer = [CALayer layer];
        self.hiLayer.frame = self.frame;
        [[self imageView].layer addSublayer:hiLayer];
        
        [self updateLayers];
        
        [self setDelaysContentTouches:NO];
        
        // tssss. a tester l'utilité avec tous les changements opérés depuis.
        for ( UIGestureRecognizer * gesture in self.gestureRecognizers){
            NSString * className = NSStringFromClass([gesture class]);
            if ( [className rangeOfString:@"Delayed"].location != NSNotFound ){
                [gesture setDelaysTouchesBegan:NO];
            }
        }
        CGSize inSize = self.frame.size;
        inSize.width-=IMAGE_MARGIN*2;
        inSize.height-=IMAGE_MARGIN*2;
        [self setZoomScale:fminf(inSize.width/self.contentSize.width,inSize.height/self.contentSize.height)];

    }
    return self;
}

- (void)dealloc
{
    [shapesLayer release];
    [thumbnailsLayer release];
    dispatch_release(hrQueue);
    if ( hasDelayedAction )
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

#pragma mark - Update shape layers

- (void) updateLayers
{
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    DisplayMode mode = self.editController.mode, previousMode = self.editController.previousMode;
    
    bool needsAlphaAnimation = (mode==kDisplayModeNotesThumbnails || previousMode==kDisplayModeNotesThumbnails) && mode!=previousMode;
    
    OAShape * selectedShape = [self.editController.selectedNote selectedShape];
    
    switch ( previousMode ) {
        case kDisplayModeNotesThumbnails:
            [self.thumbnailsLayer removeFromSuperlayer];
            break;
        default:
            while ( self.shapesLayer.sublayers.count ){
                [(CALayer *)[self.shapesLayer.sublayers objectAtIndex:0] removeFromSuperlayer];
            }
            [self.shapesLayer removeFromSuperlayer];
            break;
    };
    
    switch ( mode ) {
        case kDisplayModeNotesThumbnails:{
            for ( OpenAnnotation * note in self.editController.notes )
                [self.thumbnailsLayer addSublayer:note.thumbnailLayer];
            [self.imageView.layer addSublayer:self.thumbnailsLayer];
            break;
        }
        default:{
            for ( OAShape * shape in self.editController.selectedNote.shapes ){
                if ( shape != selectedShape ){
                    [self.shapesLayer addSublayer:shape.layer];
                }
            }
            if ( self.editController.selectedNote.selectedShape ){
                [self.shapesLayer addSublayer:selectedShape.layer];
            }
            [self.imageView.layer addSublayer:self.shapesLayer];
            break;
        }
    };
    
    [self.editController updateZoomView];
    
    [CATransaction commit];
    
    if ( needsAlphaAnimation ){
        CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.fromValue = [NSNumber numberWithFloat:0.0];
        animation.toValue = [NSNumber numberWithFloat:1.0];
        animation.duration = 0.25f;
        if ( mode == kDisplayModeNotesThumbnails ){
            [self.thumbnailsLayer addAnimation:animation forKey:@"opacity"];
        }
        else {
            [self.shapesLayer addAnimation:animation forKey:@"opacity"];
        };
    };
};

#pragma mark - Hi-res display

/*
 
    Sets the operationId to 0 to prevent dispatch_asyncs to run.
 
 */
- (void) invalidateHiResDeferredUpdates
{
    operationId = 0;
    [self.editController.hiresActivityIndicator stopAnimating];
}

- (void) updateHiResView
{
    
    if ( self.zoomScale < 1.0f ){
        hiLayer.contents = nil;
        return;
    }
    
    uint currentOperationId = operationId;
    
    dispatch_async( hrQueue ,^{
        
        /*
         
         OperationId will be incremented just __after__ dispatch_async call and will be equal to its value+1 by the time
         of the execution just below, unless other calls are made before this call.
         operationId and currentOperationId comparison ensure only the latest async call is processed.
         
         */
        
        
        if ( currentOperationId+1 == operationId && [self editController] ){
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.editController.hiresActivityIndicator startAnimating];
            });
            
            CGRect rect = CGRectZero;
            CGFloat scale = 1/self.zoomScale;
            CGPoint point = self.contentOffset;
            rect.origin = CGPointApplyAffineTransform( point, CGAffineTransformMakeScale(scale,scale ));
            rect.size = CGSizeApplyAffineTransform(self.frame.size, CGAffineTransformMakeScale(self.zoomScale, self.zoomScale));
            
            CGRect visibleRect = CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(scale, scale));
            
            // insets corrections
            if ( visibleRect.origin.x < 0 ){
                visibleRect.size.width -= visibleRect.origin.x;
                visibleRect.origin.x = 0;
            }
            if ( visibleRect.origin.y < 0 ){
                visibleRect.size.height -= visibleRect.origin.y;
                visibleRect.origin.y = 0;
            }
            if ( visibleRect.origin.x + visibleRect.size.width > self.editController.image.size.width )
                visibleRect.size.width -= (visibleRect.origin.x + visibleRect.size.width - self.editController.image.size.width);
            if ( visibleRect.origin.y + visibleRect.size.height > self.editController.image.size.height )
                visibleRect.size.height -= (visibleRect.origin.y + visibleRect.size.height - self.editController.image.size.height);
            
            CGImageRef croppedImage = CGImageCreateWithImageInRect(self.editController.image.CGImage,visibleRect);
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            hiLayer.contents = (id)croppedImage;
            self.hiLayer.frame = visibleRect;
            [CATransaction commit];
            CGImageRelease(croppedImage);
            
            
        } else {
            
            //NSLog(@"exec block annulée. %d",currentOperationId);
            
        };
        
        if ( currentOperationId+1 == operationId ){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.editController.hiresActivityIndicator stopAnimating];
            });
        }
        
    });
    
    operationId++;
    
}


#pragma mark -
#pragma mark Touch, Move and Resize events

- (void)setContentOffset:(CGPoint)contentOffset
{
    [super setContentOffset:contentOffset];
    [self.editController updateZoomView];
}

- (void)setContentSize:(CGSize)contentSize
{
    
    previousContentSize = self.contentSize;
    
    [super setContentSize:contentSize];
    
    CGFloat ratio = previousContentSize.width/self.contentSize.width;
    if ( ratio == 0.0f ) ratio = 1.0f;
    DisplayMode mode = self.editController.mode;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    CGFloat zScale = 1/self.zoomScale;
    
    [self.editController updateZoomView];
    if ( mode == kDisplayModeNotesThumbnails ){
        for ( OpenAnnotation * note in self.editController.notes ) {
            CALayer * layer = [note thumbnailLayer];
            layer.transform =  CATransform3DScale(layer.transform, ratio, ratio, 1.0f);
        };
    }
    else {
        for ( OAShape * shape in self.editController.selectedNote.shapes ){
            [shape updateLayerForScale:zScale mode:kTransformModeCSize];
        }

    };
    [CATransaction commit];
}

#pragma mark - Touch delayed actions

/*
 
 TouchesBegan actions concerning pathes and polygons are delayed to let the user the time to make a zoom action using 2 fingers.
 If we don't delay these actions, the user who wants to zoom will also plot a point if he is in edit mode.
 
 */

- (void) delayedActionEditFree:(id)arg
{
    CGPoint tPoint = [currentTouch locationInView:self.imageView];
    CGFloat scaleRatio = 1/self.zoomScale;
    OAShape * s = [[OAShape alloc] initWithType:kShapeTypePath element:CGPathElementCreate(kCGPathElementMoveToPoint,tPoint)];
    [self.editController.selectedNote addShape:s];
    [self.editController selectShape:s];
    [s updateLayerForScale:scaleRatio mode:kTransformModeSet];
    [s release];
    [self updateLayers];
    selectedPointIndex = 0;
    hasDelayedAction = NO;
    self.scrollEnabled = NO;
    self.editController.shapeCloseButton.enabled = NO;
    self.editController.shapeEndButton.enabled = NO;
    
    [UIView animateWithDuration:0.25f animations:^{
        self.editController.shapeCloseButton.alpha = DISABLED_SHAPE_BUTTONS_ALPHA;
        self.editController.shapeEndButton.alpha = DISABLED_SHAPE_BUTTONS_ALPHA;
    }];
    
}

- (void) delayedActionEditPolygon:(id)arg
{
    CGPoint tPoint = [currentTouch locationInView:self.imageView];
    CGFloat scaleRatio = 1/self.zoomScale;
    OAShape * shape = self.editController.selectedShape;
    if ( shape ){
        // if a shape is selected, we add a point, and we update UI.
        selectedPointIndex = [shape addPoint:tPoint]-1;
        
        // Under 3 points a path cannot be closed since it is a line
        self.editController.shapeCloseButton.enabled = shape.pathLength>2;
        // Under 2 points a path cannot be stopped since it is a point
        self.editController.shapeEndButton.enabled = shape.pathLength>1;
        
        [UIView animateWithDuration:0.25f animations:^{
            self.editController.shapeCloseButton.alpha = self.editController.shapeCloseButton.enabled ? 1 : DISABLED_SHAPE_BUTTONS_ALPHA;
            self.editController.shapeEndButton.alpha = self.editController.shapeEndButton.enabled ? 1 : DISABLED_SHAPE_BUTTONS_ALPHA;
        }];
        
    } else {
        // no shape selected, we create one and set it as selected.
        OAShape * s = [[OAShape alloc] initWithType:kShapeTypePolygon element:CGPathElementCreate(kCGPathElementMoveToPoint,tPoint)];
        [self.editController.selectedNote addShape:s];
        [self.editController selectShape:s];
        [s updateLayerForScale:scaleRatio mode:kTransformModeSet];
        [s release];
        [self updateLayers];
        selectedPointIndex = 0;
    };
    hasDelayedAction = NO;
    self.scrollEnabled = NO;
}

#pragma mark - Touches

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
 
    [self.editController dismissKeyboardAndNavigationView];
    
    [currentTouches unionSet:touches];
    
    DisplayMode mode = self.editController.mode;
    OAShape * shape = [self.editController selectedShape];
    
    if ( currentTouches.count > 1){
        // if on multitouch, cancel delayed actions and ignore the rest.
        if ( hasDelayedAction ){
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            hasDelayedAction = NO;
        }
        return;
    }
    
    BOOL doubleTap = NO;
    if ( currentTouches.count == 1){
        doubleTap = (CFAbsoluteTimeGetCurrent()-lastTouchTime) < DOUBLETAP_DELAY;
        lastTouchTime = CFAbsoluteTimeGetCurrent();
    };
        
    CGFloat minDistance = 50.0f / self.zoomScale;
    CGFloat scaleRatio = 1/self.zoomScale;
    
    if ( self.currentTouch == nil || [currentTouches containsObject:self.currentTouch]==NO ){
        [self setCurrentTouch:[currentTouches anyObject]];
        selectedPointIndex = -10;
    };
        
    CGPoint tPoint = [currentTouch locationInView:self.imageView];
    
    if ( mode == kDisplayModeNotesThumbnails ){
        
        OpenAnnotation * touchedNote = nil;
        CGFloat shortestDistance = fmaxf(self.frame.size.height,self.frame.size.width);
        for ( OpenAnnotation * note in self.editController.notes){
            CGPoint nPoint = [note boundingBox].origin;
            CGFloat distance = CGDistance(tPoint, nPoint);
            if ( distance < minDistance && distance < shortestDistance){
                shortestDistance = distance;
                touchedNote = note;
            }
        };
        if ( touchedNote != nil ){
            [self.editController selectNote:touchedNote];
        };
        
    }
    else if ( mode == kDisplayModeEditRectangle || mode == kDisplayModeEditEllipse ){
        
        CGRect r = CGRectMake(tPoint.x, tPoint.y, 10 * scaleRatio, 10 * scaleRatio );
        OAShape * s = [[OAShape alloc] initWithType:(mode == kDisplayModeEditEllipse ? kShapeTypeEllipse : kShapeTypeRectangle) rect:r];
        [self.editController.selectedNote addShape:s];
        [s updateLayerForScale:scaleRatio mode:kTransformModeSet];
        [s release];
        [self.editController selectShape:s];
        [self.editController setMode:kDisplayModeEditNote];
        selectedPointIndex = 2;
        
    }
    else if (mode == kDisplayModeEditFree ){
        
        hasDelayedAction = YES;
        self.scrollEnabled = NO;
        [self performSelector:@selector(delayedActionEditFree:) withObject:nil afterDelay:MULTITOUCH_DELAY];
        return;
    }
    else if (mode == kDisplayModeEditPolygon ){
        
        hasDelayedAction = YES;
        self.scrollEnabled = NO;
        [self performSelector:@selector(delayedActionEditPolygon:) withObject:nil afterDelay:MULTITOUCH_DELAY];
        return;

    }
    else if (mode == kDisplayModeEditMagicWand ){
        
        [self.editController findShapeAt:tPoint];
        
    }
    else if ( mode == kDisplayModeNote || mode == kDisplayModeNotesShapes ){
        
        // added 09 jan. 2013 on request : double tap a shape switches to edit mode and select touched shape.
        if ( doubleTap ){
            touchedShape = nil;
            for ( OAShape * s in self.editController.selectedNote.shapes ){
                if ( s.isClosed == NO ){
                    if ( [s closestDistanceToPath:tPoint] < minDistance ) touchedShape = s;
                } else {
                    if ( CGPathContainsPoint(s.path, NULL, tPoint, true) ) {
                        touchedShape = s;
                    };
                }
            };
            if ( touchedShape ){
                [self.editController setMode:kDisplayModeEditNote];
                [self.editController selectShape:touchedShape];
                if ( touchedShape ){
                    // we move the newly selected shape on top of shapes.
                    [touchedShape.layer removeFromSuperlayer];
                    [self.shapesLayer addSublayer:touchedShape.layer];
                };
            }
        }
        
    }
    else if ( mode == kDisplayModeEditNote ){
        
        /*
         
         Listens to touches and select a shape upon touch.
         Checks where is the closest point and to what it is close to.
         
         */
        
        selectedPointIndex = -10;
        CGFloat shortestDistance = fmaxf(self.frame.size.height,self.frame.size.width);
        
        if ( shape  ){
            
            if ( shape.type != kShapeTypePath ){
                // le centre du path
                if (shape.type == kShapeTypeRectangle || shape.type == kShapeTypeEllipse ) {
                    CGFloat distance = CGDistance(tPoint,[shape centerPoint]);
                    if ( distance < minDistance && distance < shortestDistance){
                        shortestDistance = distance;
                        selectedPointIndex = -10;
                    };
                }
                
                // les points du path
                for( uint i=0;i<shape.pathLength;i++){
                    CGFloat distance = CGDistance(tPoint,[shape pointAt:i]);
                    if ( distance < minDistance && distance < shortestDistance){
                        // 
                        shortestDistance = distance;
                        selectedPointIndex = i;
                    };
                };
            }
            
            if (shape.type == kShapeTypeRectangle || shape.type == kShapeTypeEllipse) {
                for ( uint i=0;i<4;i++){
                    CGFloat distance = CGDistance(tPoint,[shape midAnchorPointAt:i]);
                    if ( distance < minDistance && distance < shortestDistance){
                        shortestDistance = distance;
                        selectedPointIndex = (i*-1)-1;
                    };
                }
            }
        };
        
        // No anchor point found in current selected shape, we try to find another selected shape, if doubleTap.
        if ( selectedPointIndex==-10 ){
            
            touchedShape = nil;
            for ( OAShape * s in self.editController.selectedNote.shapes ){
                if ( s.isClosed == NO ){
                    if ( [s closestDistanceToPath:tPoint] < minDistance ) touchedShape = s;
                } else {
                    if ( CGPathContainsPoint(s.path, NULL, tPoint, true) ) {
                        touchedShape = s;
                    };
                }
            };
            
            if ( doubleTap ){
                
                [self.editController selectShape:touchedShape];
                
                if ( touchedShape && (touchedShape != shape) ){
                    // if the shape is not the prev one, we move the newly selected shape on top of shapes.
                    [touchedShape.layer removeFromSuperlayer];
                    [self.shapesLayer addSublayer:touchedShape.layer];
                };
            }
        }        
    };
    
    /*
        scroll is enabled if
        - currenttouches > 1
        - we don't have a selected shape.
        - or we have a selected shape but no touched shape and no selectedPoint.
     
        must check again on touch ended / touch cancelled.
     
     */
    
    self.scrollEnabled = touches.count>1 ? YES : selectedPointIndex>-10 ? NO : self.editController.mode == kDisplayModeEditFree ? NO : !(shape!=nil && (touchedShape==shape || selectedPointIndex!=-10));
};

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    DisplayMode mode = self.editController.mode;
    OAShape * shape = [self.editController selectedShape];
    CGPoint tPoint = [currentTouch locationInView:self.imageView];
    
    if ( mode == kDisplayModeEditPolygon && hasDelayedAction ){
        [self.editController setNoteIsModified:YES];
        return;
    }
    
    if ( mode == kDisplayModeEditFree ){
        if ( hasDelayedAction == NO && selectedPointIndex > -10 && currentTouches.count==1 ){
            [shape addPoint:tPoint];
            bool longEnoughToClose = [shape pathPerimeter:50.0f] >= 50.0f;
            self.editController.shapeCloseButton.enabled = longEnoughToClose;
            self.editController.shapeEndButton.enabled = longEnoughToClose;
            [self.editController setNoteIsModified:YES];
            [UIView animateWithDuration:0.25f animations:^{
                self.editController.shapeCloseButton.alpha = self.editController.shapeCloseButton.enabled ? 1 : DISABLED_SHAPE_BUTTONS_ALPHA;
                self.editController.shapeEndButton.alpha = self.editController.shapeEndButton.enabled ? 1 : DISABLED_SHAPE_BUTTONS_ALPHA;
            }];
        }
    }
    else if ( mode == kDisplayModeEditPolygon ){
        if ( hasDelayedAction == NO && selectedPointIndex > -10 && currentTouches.count==1 ){
            [self.editController setNoteIsModified:YES];
            [shape setPoint:tPoint at:selectedPointIndex];
        }
    }
    else if ( mode == kDisplayModeEditNote ){
        
        [self.editController setNoteIsModified:YES];
        if ( shape && [touches containsObject:self.currentTouch]) {
            // If we have a shape selected, and if the "editing finger" has moved ...
            
            if ( selectedPointIndex > -10 ){
                // If we have a selected point, we modify the shape's shape
                [shape setPoint:tPoint at:selectedPointIndex];
            
            }
            // If not, and if we are somewhere in the inside of the shape, then we modify the shape position.
            else if ( touchedShape == shape ){
                
                tPoint = [currentTouch locationInView:self.imageView];
                CGPoint pPoint = [currentTouch previousLocationInView:self.imageView];
                CGPoint offset = CGPointMake( tPoint.x-pPoint.x, tPoint.y-pPoint.y );
                [shape translate:offset];

            };
        };
    };
};

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [currentTouches minusSet:touches];
    DisplayMode mode = self.editController.mode;
    
    if ( [touches containsObject:currentTouch] ){
        
        if ( mode == kDisplayModeEditNote ){
            
            selectedPointIndex = -1;
            touchedShape = nil;
            [self setScrollEnabled:YES];
            
        }
        else if ( mode == kDisplayModeEditPolygon && hasDelayedAction ){
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            hasDelayedAction = NO;
        }
        else if ( mode == kDisplayModeEditFree ){
            if ( hasDelayedAction ){
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                hasDelayedAction = NO;
            }
            /*
            self.editController.shapeCloseButton.enabled = NO;
            self.editController.shapeEndButton.enabled = NO;
            [UIView animateWithDuration:0.25f animations:^{
                self.editController.shapeCloseButton.alpha = DISABLED_SHAPE_BUTTONS_ALPHA;
                self.editController.shapeEndButton.alpha = DISABLED_SHAPE_BUTTONS_ALPHA;
            }];
             */
        }
        [self.editController updateZoomComposite];
        [self setCurrentTouch:nil];
        
    }
    
};

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // beurk
    [self touchesEnded:touches withEvent:event];
};

#pragma mark - Override layoutSubviews to center content

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen.
    CGSize boundsSize = self.bounds.size;
    boundsSize.width-=IMAGE_MARGIN*2;
    boundsSize.height-=IMAGE_MARGIN*2+44*2;
    CGRect frameToCenter = self.imageView.frame;
        
    // when bounds change, animate the transition ( toogleShapePanel display transition weirdness )
    previousBoundsSize = boundsSize;
    previousZoomScale = self.zoomScale;
    
    // Center horizontally.
    if (frameToCenter.size.width < boundsSize.width){
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }
    else
        frameToCenter.origin.x = 0;
    
    // Center vertically.
    
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.imageView.frame = frameToCenter;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    DisplayMode mode = self.editController.mode;
    CGFloat zScale = 1/self.zoomScale;
    if ( mode == kDisplayModeNotesThumbnails )
        for ( OpenAnnotation * note in self.editController.notes )
            [note thumbnailLayer].transform = CATransform3DMakeScale(zScale, zScale, 1.0f);
    else
        for ( OAShape * shape in self.editController.selectedNote.shapes )
            [shape updateLayerForScale:zScale mode:kTransformModeSet];
    
    [CATransaction commit];
}

#pragma mark - UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    operationId++;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    operationId++;
}


- (void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self updateHiResView];
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateHiResView];
}


/* 
 A UIScrollView delegate callback, called when the user stops zooming.
 When the user stops zooming, updates the hi-res view and updates the shapes scales.
 */

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self updateHiResView];
    
    DisplayMode mode = self.editController.mode;
    
    CGFloat zScale = 1/self.zoomScale;
    
    if ( mode == kDisplayModeNotesThumbnails ){
        for ( OpenAnnotation * note in self.editController.notes ) {
            [note thumbnailLayer].transform = CATransform3DMakeScale(zScale, zScale, 1.0f);
        }
    }
    else {
        for ( OAShape * shape in self.editController.selectedNote.shapes ){
            [shape updateLayerForScale:zScale mode:kTransformModeSet];
        }
    }

}

@end

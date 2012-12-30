//
//  OAShapeObject.m
//  OAProto
//
//  Created by Ivan Touzeau on 18/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "OAShape.h"
#import "OAScrollView.h"
#import <QuartzCore/QuartzCore.h>
#import "OpenAnnotation.h"

@interface OAShape ()

@property (nonatomic,retain) CAShapeLayer       * pathLayer;
@property (nonatomic,retain) CAShapeLayer       * selLayer;
@property (nonatomic,retain) CALayer            * anchorsLayer;
@property (nonatomic,retain) CALayer            * midAnchorsLayer;

@end

@implementation OAShape
{
    CGPathElement   * elements;
    CGPoint         * midPoints;
    
    uint              length;
    uint              mLength;
    
    CAShapeLayer    * pathLayer;
    CAShapeLayer    * selLayer;
    CALayer         * anchorsLayer;
    CALayer         * midAnchorsLayer;

    BOOL              closedPath;
    
    BOOL              selected;
    
    uint              shapeType;
    
    CGFloat           displayScale;
    CGAffineTransform transform;
    
}


@synthesize layer, note, pathLayer, selLayer, anchorsLayer, midAnchorsLayer, path;


- (uint) type
{
    return shapeType;
}

- (CGPathElement *) getElements
{
    return elements;
}

- (CGPathElement *) createElementsWithLength:(uint)count
{
    CGPathElement * _elements = NULL;
    mLength = count+MLENOFFSET;
    length = count;
    _elements = malloc( sizeof(CGPathElement) * mLength );
    bzero( _elements, sizeof(CGPathElement) * mLength );
    return _elements;
}

- (CGPathRef) path
{
    return path;
    //return pathLayer.path;
}

- (void) closePath
{
    //[self addElement:CGPathElementCreate(kCGPathElementCloseSubpath,CGPointZero)];
    [self addElement:CGPathElementCreateClose()];
    closedPath = YES;
    [self updatePath];
    [self setLayerAppearance];
}

- (BOOL) isClosed
{
    return closedPath;
}

- (CGPoint) centerPoint
{
    CGPoint retval = CGPointZero;
    if ( self.type == kShapeTypeEllipse || self.type == kShapeTypeRectangle ){
        retval = CGPointMean([self pointAt:0], [self pointAt:2]);
    } else {
        // the mean point ? beurk.
        for (uint i=0; i<self.pathLength; i++) {
            retval.x+=[self pointAt:i].x;
            retval.y+=[self pointAt:i].y;
        }
        retval.x /= self.pathLength;
        retval.y /= self.pathLength;
    }
    return retval;
}

- (CGPoint) pointAt:(uint)index
{
    uint elementType = elements[index].type;
    // kCGPathElementCloseSubpath has no points, so retourns the first one as default.
    if ( elementType == kCGPathElementCloseSubpath )
        return elements[0].points[0];
    return elements[index].points[0];
}

- (uint) addPoint:(CGPoint)point
{
    return [self addElement:CGPathElementCreate(kCGPathElementAddLineToPoint, point)];
}

- (uint) insertElement:(CGPathElement)element at:(uint)index
{
    if ( index == length ){
        [self addElement:element];
    } else {
        uint newLength = length+1;
        if ( newLength >= mLength - (uint)MLENOFFSET/2 ){
            uint nmLength = mLength+1+MLENOFFSET;
            CGPathElement * _elements = realloc(elements, sizeof(CGPathElement) * nmLength );
            if ( _elements == NULL ){
                return length;
            } else {
                elements = _elements;
                mLength = nmLength;
            }
        };
        memmove(elements+index+1,elements+index, sizeof(CGPathElement)*(newLength-index-1));
        elements[index] = element;
        length = newLength;
    }
    [self updatePath];
    return length;
}

- (uint) addElement:(CGPathElement)element
{
    uint newLength = length+1;
    if ( newLength >= mLength - (uint)MLENOFFSET/2 ){
        uint nmLength = mLength+1+MLENOFFSET;
        CGPathElement * _elements = realloc(elements, sizeof(CGPathElement) * nmLength );
        if ( _elements == NULL ){
            return length;
        } else {
            elements = _elements;
            mLength = nmLength;
        }
    };
    elements[length] = element;
    length = newLength;
    [self updatePath];
    return length;
}

- (uint) removeElementAt:(uint)index
{
    uint newLength = length - 1;
    memmove(elements+index,elements+index+1, sizeof(CGPathElement)*(newLength-index));
    if ( mLength > MLENOFFSET*2 ){
        if ( newLength < mLength - MLENOFFSET*2 ){
            uint nmLength = mLength - MLENOFFSET;
            CGPathElement * _elements = realloc(elements, sizeof(CGPathElement) * nmLength);
            if ( _elements == NULL ){
                return length;
            } else {
                elements = _elements;
                mLength = nmLength;
            }
        }
    };
    length = newLength;
    [self updatePath];
    return length;
}

- (void) setPoint:(CGPoint)point at:(uint)i
{
    
    point.x = roundf(point.x);
    point.y = roundf(point.y);
    
    if ( shapeType == kShapeTypeRectangle || shapeType == kShapeTypeEllipse ){
        
        if ( i == 0 ){
            elements[0].points[0].x = elements[3].points[0].x = point.x;
            elements[0].points[0].y = elements[1].points[0].y = point.y;
        } else if ( i == 1 ){
            elements[1].points[0].x = elements[2].points[0].x = point.x;
            elements[1].points[0].y = elements[0].points[0].y = point.y;
        } else if ( i == 2 ){
            elements[2].points[0].x = elements[1].points[0].x = point.x;
            elements[2].points[0].y = elements[3].points[0].y = point.y;
        } else if ( i == 3 ){
            elements[3].points[0].x = elements[0].points[0].x = point.x;
            elements[3].points[0].y = elements[2].points[0].y = point.y;
        }
        
        // point index is a mid anchor point
        
        else if ( i == -1 ){
            elements[0].points[0].y = elements[1].points[0].y = point.y;
        }
        else if ( i == -2 ){
            elements[1].points[0].x = elements[2].points[0].x = point.x;
        }
        else if ( i == -3 ){
            elements[2].points[0].y = elements[3].points[0].y = point.y;
        }
        else if ( i == -4 ){
            elements[3].points[0].x = elements[0].points[0].x = point.x;
        };
        
    }
    
    else {
        
        elements[i].points[0] = point;
        
    }
    [self updatePath];
}

- (void) translate:(CGPoint )t
{
    for ( uint i=0;i<length;i++ ){
        if ( elements[i].type != kCGPathElementCloseSubpath ){
            elements[i].points[0].x += roundf(t.x);
            elements[i].points[0].y += roundf(t.y);
        };
    };
    [self updatePath];
}

- (uint) pathLength
{
    return length;
}

/*
 
 max allows to stop counting when max value is reached 
 
 */
- (CGFloat) pathPerimeter:(CGFloat)max
{
    CGFloat retval = 0;
    if ( length < 2 )
        return 0;
    for ( uint i=1;i<length;i++){
        retval += CGDistance(elements[i-1].points[0], elements[i].points[0]);
        if ( retval >= max )
            return retval;
    }
    return retval;
}

- (CGPoint) midAnchorPointAt:(uint)index
{
    return CGPointMean(elements[index].points[0], elements[(index+1)%(length-1)].points[0]) ;
}


- (void) updateLayerForScale:(CGFloat)scale mode:(uint)mode
{
    displayScale = scale;
    pathLayer.lineWidth = selLayer.lineWidth = SHAPE_LINE_WIDTH * scale;
    if ( selected ){
        
        [self updateDashPattern];
        
        for ( CALayer * l in anchorsLayer.sublayers )
            l.transform = CATransform3DMakeScale( scale, scale, 1.0f);
        
        for ( CALayer * l in midAnchorsLayer.sublayers )
            l.transform = CATransform3DMakeScale( scale, scale, 1.0f);
    }
}

- (void) updatePath
{
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    // add 0.5 to have neat lines.
    CGAffineTransform offset = CGAffineTransformMakeTranslation(0.5, 0.5);
    
    if ( shapeType == kShapeTypeEllipse ){
        CGFloat width  = elements[1].points[0].x-elements[0].points[0].x;
        CGFloat height = elements[2].points[0].y-elements[0].points[0].y;
        CGRect rectForOval = CGRectMake(elements[0].points[0].x,elements[0].points[0].y, width,height);
        CGPathAddEllipseInRect(pathRef, &offset, rectForOval);
    } else {
        for ( uint i=0;i<length;i++){
            CGPathElement element = elements[i];
            switch (element.type) {
                case kCGPathElementMoveToPoint:
                    CGPathMoveToPoint(pathRef, &offset, element.points[0].x, element.points[0].y);
                    break;
                case kCGPathElementAddLineToPoint:
                    CGPathAddLineToPoint(pathRef, &offset, element.points[0].x, element.points[0].y);
                    break;
                case kCGPathElementCloseSubpath:
                    CGPathCloseSubpath(pathRef);
                    break;
                default:
                    break;
            }
        }
    };
    
    if ( path )
        CGPathRelease(path);
    
    pathLayer.path = selLayer.path = path = pathRef;
    
    if ( selected )
        [self updateAnchors];
    
    [self updateLayerForScale:displayScale mode:kTransformModeSet];
}

- (void) updateAnchors
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    uint anchorsCount = shapeType == kShapeTypePath ? 0 : closedPath ? length-1 : length;
    
    if ( anchorsCount != anchorsLayer.sublayers.count ){
        
        while ( anchorsLayer.sublayers.count >= length )
            [[anchorsLayer.sublayers objectAtIndex:0] removeFromSuperlayer];

        while ( anchorsLayer.sublayers.count < anchorsCount )
            [anchorsLayer addSublayer:[self anchorLayer]];
    };
        
    if ( shapeType == kShapeTypePoint ){
        
    }
    else if ( shapeType == kShapeTypePath ){
        
    }
    else {
        
        for ( uint i=0; i < anchorsCount; i++ ){
            CGPoint point = [self pointAt:i];
            CALayer * aLayer = [anchorsLayer.sublayers objectAtIndex:i];
            aLayer.position = point;
            aLayer.transform = CATransform3DMakeScale(displayScale, displayScale, 1.0f);
        };
        
        if ( shapeType == kShapeTypeEllipse || shapeType == kShapeTypeRectangle ){
            
            for (uint i=0;i<4;i++){
                CGPoint point = [self midAnchorPointAt:i];
                CALayer * aLayer = [midAnchorsLayer.sublayers objectAtIndex:i];
                aLayer.position = point;
                aLayer.transform = CATransform3DMakeScale(displayScale, displayScale, 1.0f);
            };
        };
    };
    [CATransaction commit];

}

- (CALayer *) anchorLayer
{
    CALayer * l = [CALayer layer];
    l.backgroundColor = [UIColor whiteColor].CGColor;
    l.borderColor = [UIColor blackColor].CGColor;
    l.borderWidth = 2.0f;
    l.frame = CGRectMake(-5.5, -5.5, 10.5, 10.5);
    return l;
}

- (void) dealloc
{
    [layer release];
    layer = nil;
    free(elements);
    if ( shapeType == kShapeTypeRectangle || shapeType == kShapeTypeEllipse ){
        free(midPoints);
    }
    [super dealloc];
}

- (void) setRect:(CGRect) rect
{
    CGPoint o = rect.origin;
    shapeType = kShapeTypeRectangle;
    free(elements);
    elements = [self createElementsWithLength:5];
    
    elements[0] = CGPathElementCreate(kCGPathElementMoveToPoint,o);
    elements[1] = CGPathElementCreate(kCGPathElementAddLineToPoint,CGPointMake(o.x+rect.size.width,o.y));
    elements[2] = CGPathElementCreate(kCGPathElementAddLineToPoint,CGPointMake(o.x+rect.size.width,o.y+rect.size.height));
    elements[3] = CGPathElementCreate(kCGPathElementAddLineToPoint,CGPointMake(o.x,o.y+rect.size.height));
    elements[4] = CGPathElementCreate(kCGPathElementCloseSubpath,CGPointZero);
    
    closedPath = YES;
    
    [self updatePath];
}

-  (id) initWithType:(uint)type rect:(CGRect)rect
{
    uint l = 5;
    CGPathElement * p = [self createElementsWithLength:l];
    CGPoint o = rect.origin;
    p[0] = CGPathElementCreate(kCGPathElementMoveToPoint,o);
    p[1] = CGPathElementCreate(kCGPathElementAddLineToPoint,CGPointMake(o.x+rect.size.width,o.y));
    p[2] = CGPathElementCreate(kCGPathElementAddLineToPoint,CGPointMake(o.x+rect.size.width,o.y+rect.size.height));
    p[3] = CGPathElementCreate(kCGPathElementAddLineToPoint,CGPointMake(o.x,o.y+rect.size.height));
    p[4] = CGPathElementCreate(kCGPathElementCloseSubpath,CGPointZero);
    
    self = [self initWithType:type elements:p length:length];
    
    if ( self ) {
        free(p);
    }
    return self;
}

- (id) initWithType:(uint)aShapeType element:(CGPathElement)aElement
{
    
    CGPathElement * p = [self createElementsWithLength:1];
    p[0] = aElement;
    
    self = [self initWithType:aShapeType elements:p length:1];
    if ( self ){
        free(p);
    }
    return self;
    
}



- (id) initWithType:(uint)aShapeType elements:(CGPathElement *)aElements length:(uint)aPointsCount
{
    self = [super init];
    
    if ( self ){
        
        // scale is the page scale, used to transform anchor positions. will be updated on updateLayerForScale(..)
        displayScale =  1.0f;
        transform = CGAffineTransformMakeScale(SCALE_RATIO, SCALE_RATIO);
        shapeType = aShapeType;
        length = aPointsCount;
        elements = [self createElementsWithLength:length];
        memcpy(elements, aElements, sizeof(CGPathElement)*length);
        
        closedPath = elements[length-1].type == kCGPathElementCloseSubpath;
        
        CALayer * l = [[CALayer layer] retain];
        [self setLayer:l];
        [l release];
        
        [self setPathLayer:[CAShapeLayer layer]];
        [self setSelLayer:[CAShapeLayer layer]];
        [self setAnchorsLayer:[CALayer layer]];
        
        if ( shapeType == kShapeTypeEllipse || shapeType == kShapeTypeRectangle ){
            [self setMidAnchorsLayer:[[CALayer layer] retain]];
            for(uint i=0;i<4;i++){
                [midAnchorsLayer addSublayer:[self anchorLayer]];
            };
        };
        
        // to be updated in scrollView afterwards, to match scale.
        pathLayer.lineWidth = selLayer.lineWidth = SHAPE_LINE_WIDTH / SCALE_RATIO;
        
        [layer addSublayer:pathLayer];
        
        selected = NO;
        [self setLayerAppearance];
        [self updatePath];
        
    };
    return self;
}

- (BOOL) selected
{
    return selected;
}

- (void) setLayerAppearance
{
    
    CGFloat fill[4] = FILL_COLOR_DEFAULT;
    
    if ( selected ){
        fill[0] *= 1.3f;
        fill[1] *= 1.3f;
        fill[2] *= 1.3f;
        fill[3]  = 0.1f;
    }
    if ( closedPath == NO ) fill[3] = 0.0f;
    
    selLayer.lineCap        = pathLayer.lineCap;
    selLayer.strokeColor    = [UIColor whiteColor].CGColor;
    
    // Dash pattern varies upon scale, so it has its own selector "updateDashPattern" that also updates animation scale.
    
    CGColorSpaceRef colorSpace      = CGColorSpaceCreateDeviceRGB();
    CGColorRef      strokeColor     = CGColorCreate(colorSpace, selected ? SEL_STROKE_COLOR_F : STROKE_COLOR_DEFAULT );
    CGColorRef      fillColor       = CGColorCreate(colorSpace, fill );
    CGColorRef      selStrokeColor  = CGColorCreate(colorSpace, SEL_STROKE_COLOR_M );
    CGColorRef      selFillColor    = CGColorCreate(colorSpace, SEL_FILL_COLOR );
    
    
    pathLayer.lineCap       = selLayer.lineCap      = SHAPE_LINE_CAP;
    pathLayer.lineJoin      = selLayer.lineJoin     = SHAPE_LINE_JOIN;
    pathLayer.strokeColor   = strokeColor;
    pathLayer.fillColor     = fillColor;
    selLayer.strokeColor    = selStrokeColor;
    selLayer.fillColor      = selFillColor;
    
    CGColorSpaceRelease(colorSpace);
    CGColorRelease(strokeColor);
    CGColorRelease(fillColor);
    CGColorRelease(selStrokeColor);
    CGColorRelease(selFillColor);
    
}

- (void) updateDashPattern
{
    selLayer.lineDashPattern = [NSArray arrayWithObjects:
                                [NSNumber numberWithInt: SEL_LINE_DASH_A*displayScale],
                                [NSNumber numberWithInt: SEL_LINE_DASH_B*displayScale],
                                nil];
    
    [selLayer removeAllAnimations];
    
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"lineDashPhase"];
    
    [animation setCalculationMode:kCAAnimationDiscrete];
    [animation setKeyTimes:[NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.00f],
                            [NSNumber numberWithFloat:0.33f],
                            [NSNumber numberWithFloat:0.66f],
                            [NSNumber numberWithFloat:1.00f],
                            nil]];
    [animation setValues:[NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0.0f],
                          [NSNumber numberWithFloat:-(SEL_LINE_DASH_A+SEL_LINE_DASH_B)*0.33*displayScale],
                          [NSNumber numberWithFloat:-(SEL_LINE_DASH_A+SEL_LINE_DASH_B)*0.66*displayScale],
                          [NSNumber numberWithFloat:-(SEL_LINE_DASH_A+SEL_LINE_DASH_B)*displayScale],
                          nil]];
    [animation setDuration:0.6f];
    
    [animation setRepeatCount:HUGE_VALF];
    
    [selLayer addAnimation:animation forKey:DASH_PHASE_ANIMATION];
    
}


- (BOOL) setSelected:(BOOL)aSelected
{
    BOOL retval = NO;
    
    if ( selected != aSelected ){
        
        selected = aSelected;
        [self setLayerAppearance];
        
        retval = YES;
        
        if ( selected ){
            
            [layer addSublayer:selLayer];
            [layer addSublayer:anchorsLayer];
            if ( shapeType == kShapeTypeEllipse || shapeType == kShapeTypeRectangle ){
                [layer addSublayer:midAnchorsLayer];
            }
            
            [self updateAnchors];
            
            [self updateDashPattern];
            
            
        } else {
            
            [selLayer removeAnimationForKey:DASH_PHASE_ANIMATION];
            [selLayer removeFromSuperlayer];
            [anchorsLayer removeFromSuperlayer];
            if ( shapeType == kShapeTypeEllipse || shapeType == kShapeTypeRectangle ){
                [midAnchorsLayer removeFromSuperlayer];
            }
        }
    }
    return retval;
}

- (CGFloat) distanceToPoint:(CGPoint)p fromLineSegmentBetween:(CGPoint)l1 and:(CGPoint)l2
{
    float A = p.x - l1.x;
    float B = p.y - l1.y;
    float C = l2.x - l1.x;
    float D = l2.y - l1.y;
    float dot = A * C + B * D;
    float len_sq = C * C + D * D;
    float param = dot / len_sq;
    float xx, yy;
    
    if (param < 0 || (l1.x == l2.x && l1.y == l2.y)) {
        xx = l1.x;
        yy = l1.y;
    }
    else if (param > 1) {
        xx = l2.x;
        yy = l2.y;
    }
    else {
        xx = l1.x + param * C;
        yy = l1.y + param * D;
    }
    
    float dx = p.x - xx;
    float dy = p.y - yy;
    
    return sqrtf(dx * dx + dy * dy);
}

- (CGFloat) closestDistanceToPath:(CGPoint)aPoint
{
    CGFloat minDistance = HUGE_VALF;
    for(uint i=0;i<length-1;i++)
        minDistance = fminf(minDistance,[self distanceToPoint:aPoint fromLineSegmentBetween:elements[i].points[0] and:elements[i+1].points[0]]);
    return minDistance;
}

@end


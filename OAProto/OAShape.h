//
//  OAShapeObject.h
//  OAProto
//
//  Created by Ivan Touzeau on 18/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

//#import <opencv2/core/types_c.h>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/objdetect/objdetect.hpp>

@class OpenAnnotation;

#define SCALE_RATIO                 1 //0.24f sur tests PDFs

# pragma mark - shape display basic options : colors, stroke width ...

#define SHAPE_LINE_WIDTH            2.0f
#define SHAPE_LINE_CAP              @"square"
#define SHAPE_LINE_JOIN             @"round"

#define SEL_LINE_DASH_A             5.0f
#define SEL_LINE_DASH_B             10.0f

#define SEL_STROKE_COLOR_F          (CGFloat[]){0.0f,0.0f,0.0f,1.0f}
#define SEL_STROKE_COLOR_M          (CGFloat[]){1.0f,1.0f,1.0f,1.0f}
#define SEL_FILL_COLOR              (CGFloat[]){0.0f,0.0f,0.0f,0.0f}

#define STROKE_COLOR_DEFAULT        (CGFloat[]){0.0f,0.0f,0.0f,1.0f}
#define FILL_COLOR_DEFAULT          (CGFloat[]){1.0f,0.0f,0.0f,0.3f}
#define DASH_PHASE_ANIMATION        @"lineDashPhaseAnimation"

# pragma mark - helpers CGRects, CGPoints

#define CGRectSetPos( r, x, y )     CGRectMake( x, y, r.size.width, r.size.height )
#define CGRectSetX( r, x )          CGRectMake( x, r.origin.y, r.size.width, r.size.height )
#define CGRectSetY( r, y )          CGRectMake( r.origin.x, y, r.size.width, r.size.height )
#define CGRectSetSize( r, w, h )    CGRectMake( r.origin.x, r.origin.y, w, h )
#define CGRectSetWidth( r, w )      CGRectMake( r.origin.x, r.origin.y, w, r.size.height )
#define CGRectSetHeight( r, h )     CGRectMake( r.origin.x, r.origin.y, r.size.width, h )

#define CGRectGetCenter(r)          CGPointMake( r.origin.x + r.size.width/2, r.origin.y + r.size.height/2 )

#define CGPointOffset(p,x,y)        CGPointMake( p.x+x, p.y+y )

#define CGPointMean(a,b)            CGPointMake( (a.x+b.x)/2, (a.y+b.y)/2 )

static CGFloat CGDistance(CGPoint point1, CGPoint point2)
{
	CGFloat dx = point2.x - point1.x;
	CGFloat dy = point2.y - point1.y;
	return sqrtf(dx*dx + dy*dy);
}

// offset to have some free memory in order to limit reallocs of the shape elements
#define MLENOFFSET                  20

# pragma mark - magic wand constants

#define MW_MAXRECTSIZE              1500.0f
#define MW_TOLERANCE_MIN            3.0f
#define MW_TOLERANCE_MAX            10.0f
#define MW_TOLERANCE                6.0f

# pragma mark - display flags enums

enum TransformMode {
    kTransformModeSet,
    kTransformModeAdd,
    kTransformModeCSize
};
typedef enum TransformMode TransformMode;

enum ShapeType {
    kShapeTypeUnknown,
    kShapeTypeRectangle,
    kShapeTypeEllipse,
    kShapeTypePolygon,
    kShapeTypeBezier,
    kShapeTypeBezierQuad,
    kShapeTypePath,
    kShapeTypePoint    
};
typedef enum ShapeType ShapeType;

#pragma mark - OpenCV/CG helpers

static CGSize CGSizeFromSeqContour(CvSeq * contour)
{
    CGFloat xmin = HUGE_VALF, xmax = 0, ymin = HUGE_VALF, ymax = 0;
    for( int i=0; i<contour->total; ++i ){
        CvPoint * p = CV_GET_SEQ_ELEM( CvPoint, contour, i );
        xmin = fminf(xmin,(CGFloat)p->x);
        xmax = fmaxf(xmax,(CGFloat)p->x);
        ymin = fminf(ymin,(CGFloat)p->y);
        ymax = fmaxf(ymax,(CGFloat)p->y);
    }
    return CGSizeMake(xmax-xmin, ymax-ymin);
}

static CGRect CGRectFromSeqContour(CvSeq * contour)
{
    CGFloat xmin = HUGE_VALF, xmax = 0, ymin = HUGE_VALF, ymax = 0;
    for( int i=0; i<contour->total; ++i ){
        CvPoint * p = CV_GET_SEQ_ELEM( CvPoint, contour, i );
        xmin = fminf(xmin,(CGFloat)p->x);
        xmax = fmaxf(xmax,(CGFloat)p->x);
        ymin = fminf(ymin,(CGFloat)p->y);
        ymax = fmaxf(ymax,(CGFloat)p->y);
    }
    return CGRectMake(xmin, ymin, xmax-xmin, ymax-ymin);
}

static CGPoint CGPointFromSeqContour(CvSeq * contour,int index, CGPoint offset)
{
    CvPoint * p = CV_GET_SEQ_ELEM( CvPoint, contour, index );
    return CGPointMake(p->x-1+offset.x, p->y-1+offset.y);
}

# pragma mark - CGPathElement helpers

typedef struct PathLength
{
    uint        length;
    uint        mLength;
} PathLength;

static uint CGPathElementLengthForType(uint type)
{
    switch (type) {
        case kCGPathElementAddCurveToPoint:
            return 3;
            break;
        case kCGPathElementAddQuadCurveToPoint:
            return 2;
            break;
        case kCGPathElementCloseSubpath:
            return 0;
            break;
        default:
            return 1;
            break;
    }
    return 1;
}

static uint CGPathElementMakeFromNSData( NSData * data, CGPathElement ** elements )
{
    uint currentLen = 100;
    CGPathElement * elems = malloc(sizeof(CGPathElement)*currentLen);
    NSRange range = NSMakeRange(0, sizeof(uint));
    int i=0;
    // NSData contains a serie of { uint ( .type ) and a CGPoint ( .points ) }.
    while ( range.location+range.length <= data.length ){
        [data getBytes:&elems[i].type range:range];
        range.location += range.length;
        uint pointsSize = CGPathElementLengthForType(elems[i].type) * sizeof(CGPoint);
        if ( pointsSize > 0 ){
            range.length = pointsSize;
            elems[i].points = malloc(pointsSize);
            [data getBytes:elems[i].points range:range];
            range.location += range.length;
        }
        range.length = sizeof(uint);
        if ( ++i > currentLen ){
            currentLen+=100;
            elems = realloc(elems, sizeof(CGPathElement) * currentLen );
        };
    };
    elems = realloc(elems, sizeof(CGPathElement)* MAX(1,i) );
    * elements = elems;
    return i;
}

static NSData * NSDataFromCGPathElement( CGPathElement * elements, uint length )
{
    NSMutableData * path = [[NSMutableData alloc] init];
    for( int i=0;i<length;i++){
        [path appendBytes:&elements[i].type length:sizeof(uint)];
        uint pointsSize = CGPathElementLengthForType(elements[i].type) * sizeof(CGPoint);
        if ( pointsSize > 0 )
            [path appendBytes:elements[i].points length:pointsSize];
    }
    return (NSData *)path;
}

// Not actually used. Question : shall I use the points argument, or a memcpy ?
// NSData methods logic says to memcpy, and the source is responsible for free'ing the argument.
static CGPathElement CGPathElementMake( uint type, CGPoint * points)
{
    CGPathElement element;
    element.type = type;
    uint len = CGPathElementLengthForType(type);
    if ( len > 0 ){
        element.points = malloc(sizeof(CGPoint)*len);
        memcpy(element.points, points, len);
    }
    return element;
}

static CGPathElement CGPathElementCreateClose()
{
    CGPathElement element;
    element.type = kCGPathElementCloseSubpath;
    return element;
}

static CGPathElement CGPathElementCreate( uint type, CGPoint point)
{
    CGPathElement element;
    element.type = type;
    uint len = CGPathElementLengthForType(type);
    if ( len > 0 ){
        element.points = malloc(sizeof(CGPoint) * len );
        element.points[0] = point;
    }
    return element;
}

// - (CGPathElement *) createElementsWithLength:(uint)count
// is defined as a private selector.

static NSString * SVGPathCommandForCGPathElement(CGPathElement element)
{
    switch ( element.type )
    {
        case kCGPathElementMoveToPoint:return @"M";
        case kCGPathElementAddLineToPoint:return @"L";
        case kCGPathElementCloseSubpath:return @"Z";
        default:return @"Z";
    }
}

static NSString * NSStringFromShapeType(uint type)
{
    switch ( type )
    {
        case kShapeTypePoint:return @"point";
        case kShapeTypeBezier:return @"bezier";
        case kShapeTypePath:return @"path";
        case kShapeTypePolygon:return @"polygon";
        case kShapeTypeRectangle:return @"rectangle";
        case kShapeTypeEllipse:return @"ellipse ( in rect )";
        default:return @"unknown shape type";
    }
}

#pragma mark - OAShape interface

@interface OAShape : NSObject
{
    
    CALayer             * layer;
    CGPathRef             path;
    
    OpenAnnotation      * note;
    
    
}

- (CGPathElement *) getElements;

- (uint)        type;

- (id)          initWithType:(uint)shapeType elements:(CGPathElement *)aElements length:(uint)aPointsCount;
- (id)          initWithType:(uint)aShapeType element:(CGPathElement )aElement;
- (id)          initWithType:(uint)type rect:(CGRect )rect;

- (void)        setRect:(CGRect) rect;

- (BOOL)        setSelected:(BOOL)aEditable;

- (void)        translate:(CGPoint )t;

- (CGPoint)     pointAt:(uint)index;
- (uint)        addPoint:(CGPoint)point;
- (void)        setPoint:(CGPoint)point at:(uint)index;
- (CGPoint)     centerPoint;

- (uint)        insertElement:(CGPathElement)element at:(uint)index;
- (uint)        addElement:(CGPathElement)element;

- (void)        closePath;
- (BOOL)        isClosed;

- (CGFloat)     closestDistanceToPath:(CGPoint)point;

- (CGPoint)     midAnchorPointAt:(uint)index;

- (uint)        pathLength;
- (CGFloat)     pathPerimeter:(CGFloat)max;

- (void)        updateLayerForScale:(CGFloat)scale mode:(uint)mode;

@property (nonatomic,retain)    CALayer             * layer;
@property (nonatomic,assign)    OpenAnnotation      * note;
@property (nonatomic,assign)    CGPathRef             path;

@end

//
//  OpenAnnotation.m
//  OAProto
//
//  Created by Ivan Touzeau on 18/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "OpenAnnotation.h"
#import "OAShape.h"

#import "Note.h"
#import "Page.h"
#import "Shape.h"
#import "User.h"

#import "DataWrapper.h"

@interface OpenAnnotation ()
{
    Note                * note;
}

@property (nonatomic,retain) Note                   * note;

@end

@implementation OpenAnnotation

@synthesize title,content,authorId,tags,status,shapes,nid;
@synthesize thumbnailLayer=_thumbnailLayer,note,selectedShape;

- (void) dealloc
{
    [super dealloc];
    if ( _thumbnailLayer ){
        [_thumbnailLayer release];
        _thumbnailLayer = nil;
    }
    [shapes release];
    shapes = nil;
    [note release];
}

- (NSString *)  creationDate
{
    NSDateFormatter * dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    return [dateFormatter stringFromDate:self.note.creationDate];
}

- (NSString *) updateDate
{
    NSDateFormatter * dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    return [dateFormatter stringFromDate:self.note.updateDate];
}

- (NSString *) userEmail
{
    return self.note.owner.email;
}
- (NSString *) userName
{
    NSString * retval = nil;
    User * owner = self.note.owner;
    if ( owner.firstName && owner.lastName ){
        retval = [NSString stringWithFormat:@"%@ %@",self.note.owner.firstName,self.note.owner.lastName];
        
    }
    else if ( owner.firstName ){
        retval = owner.firstName;
    } else if ( owner.lastName){
        retval = owner.lastName;
    }
    return retval;
}

- (NSString *) userDescription
{
    NSString * userName = self.userName;
    if ( userName.length > 1 )
        return [NSString stringWithFormat:@"%@ %@",userName,[self userEmail]];
    return [self userEmail];
}

- (id) cdDelete
{
    [note.managedObjectContext deleteObject:note];
    NSError * error = nil;
    [self.note.managedObjectContext save:&error];
    return error;
}

- (id) cdSave
{

    [note setContent:self.content];
    [note setTitle:self.title];
    [note setStatus:[NSNumber numberWithInt:self.status]];
    if ( note.creationDate == nil )
        note.creationDate = [NSDate date];
    
    note.updateDate = [NSDate date];
    
    while ( note.shapes.count )
        [note removeShapesObject:note.shapes.anyObject];
    
    for ( OAShape * shape in shapes ){
        Shape * s = [NSEntityDescription insertNewObjectForEntityForName:@"Shape" inManagedObjectContext:note.managedObjectContext];
        s.note = note;
        s.type = [NSNumber numberWithInt:shape.type];
        NSData * path = NSDataFromCGPathElement(shape.getElements, shape.pathLength);
        s.path = path;
        [note addShapesObject:s];
        [path release];
    }
    
    NSError * error = nil;
    [note.managedObjectContext save:&error];
    
    return error;
}

- (User *) owner
{
    return self.note.owner;
}

- (id) revertToSaved
{
    [self.shapes removeAllObjects];
    for ( Shape * shape in note.shapes ){
        CGPathElement * elements = NULL;
        uint length = CGPathElementMakeFromNSData(shape.path, &elements);
        OAShape * newShape = [[OAShape alloc] initWithType:shape.type.intValue elements:elements length:length];
        [self addShape:newShape];
        [newShape release];
        free(elements);
    }  
    return self;
}

- (id) initWithManagedObject:(Note *)aNote
{
    self = [super init];
    
    if ( self ){
        
        note = [aNote retain];
        
        [self setAuthorId:note.owner.uuid];
        [self setTitle:note.title];
        [self setContent:note.content];
        [self setStatus:note.status.intValue];
        [self setNid:note.index.intValue];
        self.selectedShape = nil;
        
        for ( Shape * shape in note.shapes ){
            CGPathElement * elements = NULL;
            uint length = CGPathElementMakeFromNSData(shape.path, &elements);
            OAShape * newShape = [[OAShape alloc] initWithType:shape.type.intValue elements:elements length:length];
            [self addShape:newShape];
            [newShape release];
            free(elements);
        }
        
    }
    return self;
}

- (CGPathRef) newCompositePath
{
    CGMutablePathRef cPath = CGPathCreateMutable();
    for ( OAShape * shape in shapes){
        CGPathRef pathToAdd = NULL;
        if ( shape.isClosed ){
            pathToAdd = CGPathCreateCopy(shape.path);
            //CGPathAddPath(cPath, NULL, CGPathCreateCopy(shape.path));
        } else {
            pathToAdd = CGPathCreateCopyByStrokingPath(shape.path, NULL, 10.0f, kCGLineCapButt, kCGLineJoinRound, 1.0f);
            //CGPathAddPath(cPath, NULL, CGPathCreateCopyByStrokingPath(shape.path, NULL, 10.0f, kCGLineCapButt, kCGLineJoinRound, 1.0f));
        }
        CGPathAddPath(cPath, NULL, pathToAdd);
        CGPathRelease(pathToAdd);
    }
    return cPath;
}

- (OAShape *) shapeAt:(uint)index
{
    return [shapes objectAtIndex:index];
}

- (void) setSelectedShape:(OAShape *)aShape
{
    if ( aShape == selectedShape )
        return;
    
    selectedShape = aShape;
    for ( OAShape * shape in shapes )
        [shape setSelected:aShape==shape];
    
}

- (OAShape *) closestShapeToShape:(OAShape *)aShape
{
    CGPoint mid = CGRectGetCenter(CGPathGetBoundingBox(aShape.path));
    CGFloat shortestDistance = 9999;
    OAShape * retval = nil;
    for ( OAShape * shape in shapes){
        if ( shape != aShape ){
            CGFloat distance = CGDistance(mid, CGRectGetCenter(CGPathGetBoundingBox(shape.path)));
            if ( distance < shortestDistance){
                shortestDistance = distance;
                retval = shape;
            };
        };
    };
    return retval;
}

- (uint) addShape:(OAShape *)aShape
{
    if ( shapes == nil){
        [self setShapes:[[NSMutableArray alloc] init]];
    };
    [shapes addObject:aShape];
    [aShape setNote:self];
    return [shapes count];
};

- (uint) removeShape:(OAShape *)aShape
{
    if ( aShape && [shapes containsObject:aShape] ){
        [shapes removeObject:aShape];
    };
    return [shapes count];
};

- (uint) addShapes:(id)aShapes
{
    if ( [aShapes count] ){
        for (OAShape * s in aShapes)
            [self addShape:s];
    };
    return [shapes count];
};

- (CGRect) boundingBox
{
    CGRect retval;
    if ( shapes == nil || shapes.count == 0 ){
        retval = CGRectZero;
    } else {
        retval = CGPathGetBoundingBox([self shapeAt:0].path);
        for ( uint i = 1; i< shapes.count; i++ ){
            retval = CGRectUnion(retval, CGPathGetBoundingBox([self shapeAt:i].path));
        };
    };
    return retval;
}

- (CALayer *) thumbnailLayer
{
    if ( _thumbnailLayer ){
        return _thumbnailLayer;
    }
    
    CALayer * layer = [CALayer layer];
    
    NSString * txt = [NSString stringWithFormat:@"%d",nid];
    CGFloat fontSize = 25.0f;
    CGSize txtSize = [txt sizeWithFont:[UIFont boldSystemFontOfSize:fontSize]];
    
    CAShapeLayer * imgLayer = [CAShapeLayer layer];
    UIBezierPath * p = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 5, txtSize.width+15, txtSize.height+10) cornerRadius:8.0f];
    [p moveToPoint:CGPointMake(0, 0)];
    [p addLineToPoint:CGPointMake(10,  10)];
    [p addLineToPoint:CGPointMake(0, 10)];
    [p closePath];
    imgLayer.fillColor = [UIColor orangeColor].CGColor;
    imgLayer.anchorPoint = CGPointZero;
    imgLayer.path = p.CGPath;
    imgLayer.bounds = CGPathGetBoundingBox(p.CGPath);
    imgLayer.shadowColor = [UIColor blackColor].CGColor;
    imgLayer.shadowOpacity = 0.5f;
    imgLayer.shadowRadius = 5.0f;
    imgLayer.shadowOffset = CGSizeZero;
    imgLayer.shadowPath = p.CGPath;
    [layer addSublayer:imgLayer];
    
    CATextLayer * textLayer = [CATextLayer layer];
    textLayer.anchorPoint = CGPointZero;
    textLayer.bounds = imgLayer.bounds;
    textLayer.string = txt;
    textLayer.font = [UIFont boldSystemFontOfSize:fontSize].fontName;
    textLayer.fontSize = fontSize;
    textLayer.backgroundColor = [UIColor clearColor].CGColor;
    textLayer.position = CGPointMake(5.5,10);
    textLayer.wrapped = NO;
    
    CATextLayer * textLayer2 = [CATextLayer layer];
    textLayer2.anchorPoint = textLayer.anchorPoint;
    textLayer2.bounds = textLayer.bounds;
    textLayer2.string = txt;
    textLayer2.font = textLayer.font;
    textLayer2.fontSize = textLayer.fontSize;
    textLayer2.foregroundColor = [UIColor blackColor].CGColor;
    textLayer2.backgroundColor = [UIColor clearColor].CGColor;
    textLayer2.position = CGPointMake(textLayer.position.x-0.5,textLayer.position.y-0.5);
    textLayer2.wrapped = textLayer.wrapped;
    
    [layer addSublayer:textLayer2];
    [layer addSublayer:textLayer];
    
    layer.position = [self boundingBox].origin;
    
    _thumbnailLayer = [layer retain];
        
    return _thumbnailLayer;
}

// list of all the shape layers
- (NSArray *) shapeLayers
{
    NSMutableSet * s = [NSMutableSet set];
    for ( OAShape * shape in shapes){
        [s addObject:[shape layer]];
    };
    return [s allObjects];
}

@end

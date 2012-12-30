//
//  OpenAnnotation.h
//  OAProto
//
//  Created by Ivan Touzeau on 15/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <Foundation/Foundation.h>

enum ShapeType
{
    UNDEFINED=0,
    POLYGON,
    CURVE
};

typedef struct Shape
{
	CGFloat	  * points;
    BOOL        isClosed;
    uint        type;
} Shape;

@interface OANote : NSObject {
    
    NSString        * title;
    NSString        * description;
    NSString        * authorUid;
    NSUInteger      * status;
    
    Shape           * shapes;
    
    NSArray         * shapeList;
    
}


@end

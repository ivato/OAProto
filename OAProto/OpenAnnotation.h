//
//  OpenAnnotation.h
//  OAProto
//
//  Created by Ivan Touzeau on 18/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAShape, Note, User;

@interface OpenAnnotation : NSObject
{
    
    NSString                * title;
    NSString                * textContent;
    
    NSString                * authorId;
    
    NSMutableSet            * tags;
    
    uint                      status;
    uint                      nid;
        
    NSMutableArray          * shapes;
    CALayer                 * thumbnailLayer;
    
    OAShape                 * selectedShape;
    
}

- (id)          initWithManagedObject:(Note *)note;
- (id)          revertToSaved;
- (id)          cdDelete;
- (id)          cdSave;
- (User *)      owner;

- (NSString *)  creationDate;
- (NSString *)  updateDate;
- (NSString *)  userEmail;
- (NSString *)  userName;
- (NSString *)  userDescription;

- (uint)        addShape:(OAShape *)aShape;
- (uint)        removeShape:(OAShape *)aShape;

// Awaits anything with .count
- (uint)        addShapes:(id)aShapes;

- (NSArray *)   shapeLayers;
- (CGRect)      boundingBox;
- (OAShape *)   closestShapeToShape:(OAShape *)aShape;

- (CGPathRef)   newCompositePath;

@property (nonatomic,copy)          NSString        * title;
@property (nonatomic,copy)          NSString        * content;
@property (nonatomic,retain)        NSMutableSet    * tags;

@property (nonatomic,copy)          NSString        * authorId;

@property (nonatomic,assign)        uint              status;
@property (nonatomic,assign)        uint              nid;

@property (nonatomic,retain)        NSMutableArray  * shapes;

@property (nonatomic,retain)        CALayer         * thumbnailLayer;

@property (nonatomic,assign)        OAShape         * selectedShape;


@end

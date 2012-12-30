//
//  Note.h
//  OAProto
//
//  Created by Ivan Touzeau on 22/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Page, Shape, User;

@interface Note : NSManagedObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSDate * updateDate;
@property (nonatomic, retain) User *owner;
@property (nonatomic, retain) Page *page;
@property (nonatomic, retain) NSSet *shapes;
@end

@interface Note (CoreDataGeneratedAccessors)

- (void)addShapesObject:(Shape *)value;
- (void)removeShapesObject:(Shape *)value;
- (void)addShapes:(NSSet *)values;
- (void)removeShapes:(NSSet *)values;

@end

//
//  Book.h
//  OAProto
//
//  Created by Ivan Touzeau on 21/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Page, User;

@interface Book : NSManagedObject

@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * headline;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * comments;
@property (nonatomic, retain) NSString * copyright;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSDate * lastEditTime;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * region;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSNumber * thumbnail;
@property (nonatomic, retain) NSSet *pages;
@property (nonatomic, retain) NSSet *users;
@end

@interface Book (CoreDataGeneratedAccessors)

- (void)addPagesObject:(Page *)value;
- (void)removePagesObject:(Page *)value;
- (void)addPages:(NSSet *)values;
- (void)removePages:(NSSet *)values;

- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

@end

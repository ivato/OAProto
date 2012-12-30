//
//  Page.h
//  OAProto
//
//  Created by Ivan Touzeau on 21/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Book, Note, User;

@interface Page : NSManagedObject

@property (nonatomic, retain) NSString * file;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * nextNoteIndex;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Book *book;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *users;
@end

@interface Page (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

@end

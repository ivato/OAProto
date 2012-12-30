//
//  CDWrapper.h
//  OAProto
//
//  Created by Ivan Touzeau on 07/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DataWrapperDelegate <NSObject>

@required

- (void) onSetupComplete;

@end

@class Book,Page,Note,User,OpenAnnotation;

#define CGSizeRatio(s)                  s.width/s.height

#define DEFAULT_PAGE_THUMBNAIL          @"defaultPage-s.jpg"
#define DEFAULT_BOOK_THUMBNAIL          @"defaultPage-s.jpg"

@interface DataWrapper : NSObject
{
    id <DataWrapperDelegate>      delegate;
    
    Book                        * currentBook;
    Page                        * currentPage;    
    User                        * currentUser;
}

- (NSArray *)   books;
- (NSArray *)   users;
- (User *)      createUser;
- (NSArray *)   pagesWithNotesForUser:(User *)user;
- (NSArray *)   booksWithNotesForUser:(User *)user;

- (void)        deleteUser:(User *)user;

- (BOOL)        noteIsEditable:(OpenAnnotation *)note;

// http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
+ (BOOL)        NSStringIsValidEmail:(NSString *)checkString;

- (id)          initWithContext:(NSManagedObjectContext *)context;

- (BOOL)        initDatabase;
- (NSArray *)   entitiesForName:(NSString *)entityName sortedWith:(NSString *)key;
- (id)          entityForName:(NSString *)entityName;
- (void)        logDatabase;
- (void)        testDatabase;

+ (UIImage *)   imageForPage:(Page *)page;
+ (UIImage *)   thumbnailForPage:(Page *)page;
+ (UIImage *)   thumbnailForBook:(Book *)book;
+ (NSDate *)    updateDateForPage:(Page *)page user:(User *)user;
+ (NSDate *)    creationDateForPage:(Page *)page user:(User *)user;

+ (UIImage *)   imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

- (NSData *)    xmlDataForUser:(User *)user;

@property (nonatomic,retain)    id                delegate;
@property (nonatomic,retain)    Book            * currentBook;
@property (nonatomic,retain)    Page            * currentPage;
@property (nonatomic,retain)    User            * currentUser;

@end

//
//  Shape.h
//  OAProto
//
//  Created by Ivan Touzeau on 20/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Note;

@interface Shape : NSManagedObject

@property (nonatomic, retain) NSData * path;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) Note *note;

@end

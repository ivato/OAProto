//
//  OAProtoAppDelegate.h
//  OAProto
//
//  Created by Ivan Touzeau on 15/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PanelsViewController, EditViewController, OAShape, Page, DataWrapper;

@interface OAProtoAppDelegate : UIResponder <UIApplicationDelegate> {
    
    PanelsViewController            * panelsController;
    UINavigationController          * navController;
    OAShape                         * shape;
    
    DataWrapper                     * wrapper;
    
}

- (void)    saveContext;
- (NSURL *) applicationDocumentsDirectory;

@property (strong, nonatomic)           UIWindow                        * window;

@property (readonly, strong, nonatomic) NSManagedObjectContext          * managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel            * managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    * persistentStoreCoordinator;

@property (nonatomic, retain)           UINavigationController          * navController;
@property (nonatomic, retain)           PanelsViewController            * panelsController;
@property (nonatomic, retain)           EditViewController              * editController;
@property (nonatomic, retain)           DataWrapper                     * wrapper;

@end

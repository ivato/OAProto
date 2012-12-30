//
//  NotesViewController.h
//  OAProto
//
//  Created by Ivan Touzeau on 22/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    
    PageNavigationModeBook,
    PageNavigationModeUserNotes
    
} PageNavigationMode;

@class EditViewController;

@interface NotesViewController : UITableViewController

- (id) initWithEditController:(EditViewController *)controller;
//- (id) initWithMode:(PageNavigationMode)mode;

@end

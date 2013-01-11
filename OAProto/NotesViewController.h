//
//  NotesViewController.h
//  OAProto
//
//  Created by Ivan Touzeau on 22/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//
//  NotesViewController displays the notes as a simple vertical list.

#import <UIKit/UIKit.h>

typedef enum {
    
    PageNavigationModeBook,
    PageNavigationModeUserNotes
    
} PageNavigationMode;

@class EditViewController;

@interface NotesViewController : UITableViewController

- (id) initWithEditController:(EditViewController *)controller;

@end

//
//  PanelsViewController.h
//  OAProto
//
//  Created by Ivan Touzeau on 15/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//
//  PanelsViewController is the home view.
//  The folded view that reveals pages when touching a cover is handled by FolderViewController.

#import <UIKit/UIKit.h>
#import "PSTCollectionView.h"
#import "FolderViewController.h"
#import "DataWrapper.h"
#import "UserViewController.h"
#import "EditViewController.h"

@interface PanelsViewController : UIViewController <EditControllerDelegate, UserViewDelegate, FolderViewDelegate, DataWrapperDelegate, PSTCollectionViewDataSource, PSTCollectionViewDelegate>
{
}

@end

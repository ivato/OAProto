//
//  PanelsViewController.h
//  OAProto
//
//  Created by Ivan Touzeau on 15/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

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

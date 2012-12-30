//
//  UserViewController.h
//  OAProto
//
//  Created by Ivan Touzeau on 27/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MessageUI/MessageUI.h>

@class User;

@protocol UserViewDelegate <NSObject>

@optional

- (void) onSaveButtonClicked:(User *)user;

@end

@interface UserViewController : UIViewController <MFMailComposeViewControllerDelegate>
{
    id <UserViewDelegate>           delegate;
}

- (id) initWithUser:(User *)user;

- (IBAction)onSaveButtonClicked:(id)sender;

@property (nonatomic,assign)    id              delegate;

@end

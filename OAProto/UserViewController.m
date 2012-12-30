//
//  UserViewController.m
//  OAProto
//
//  Created by Ivan Touzeau on 27/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "UserViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OAProtoAppDelegate.h"
#import "DataWrapper.h"

#import "User.h"

@interface UserViewController ()
{
}

@property (nonatomic,retain) IBOutlet   UILabel                 * titleLabel;
@property (nonatomic,retain) IBOutlet   UITextField             * firstnameTextField;
@property (nonatomic,retain) IBOutlet   UITextField             * lastnameTextField;
@property (nonatomic,retain) IBOutlet   UITextField             * emailTextField;
@property (nonatomic,retain) IBOutlet   UITextField             * organisationTextField;
@property (nonatomic,retain) IBOutlet   UIButton                * saveButton;
@property (nonatomic,retain) IBOutlet   UIButton                * cancelButton;
@property (nonatomic,retain) IBOutlet   UIButton                * exportButton;
@property (nonatomic,retain) IBOutlet   UIButton                * selectButton;
@property (nonatomic,retain)            User                    * user;

@property (nonatomic,assign)            DataWrapper             * wrapper;
@property (nonatomic,assign)            BOOL                      userIsFirstUser;

@end

@implementation UserViewController

@synthesize delegate;

- (IBAction) labelValueDidChange:(id)sender
{
    [self updateEmailTextFieldColor];
    [self.saveButton setEnabled:[DataWrapper NSStringIsValidEmail:self.emailTextField.text]];
    [self.saveButton setAlpha:self.saveButton.enabled ? 1 : 0.5];
}

- (IBAction) onSelectButtonClicked:(id)sender
{
    [self.wrapper setCurrentUser:self.user];
    self.selectButton.enabled = NO;
    self.selectButton.alpha = 0.5f;
}

- (IBAction) onSaveButtonClicked:(id)sender
{
    self.user.email = self.emailTextField.text;
    self.user.firstName = self.firstnameTextField.text;
    self.user.lastName = self.lastnameTextField.text;
    self.user.organisation = self.organisationTextField.text;
    
    NSError * error = nil;
    [self.user.managedObjectContext save:&error];
    if ( error == nil ){
        if ( self.wrapper.users.count == 1 ){
            [self.wrapper setCurrentUser:self.user];
        }
        if ( self.modalPresentationStyle == UIModalPresentationFormSheet ){
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                [self.delegate onSaveButtonClicked:self.user];
            }];
        }
    }
};

- (id) initWithUser:(User *) user
{
    self = [super initWithNibName:@"UserViewController" bundle:nil];
    if ( self ){
        self.wrapper = [(OAProtoAppDelegate *)[UIApplication sharedApplication].delegate wrapper];
        if ( user == nil )
            user = [self.wrapper.users objectAtIndex:0];
        [self setUser:user];
        self.userIsFirstUser = (self.wrapper.users.count == 1);
    }
    return self;
}

- (IBAction) onCancelButtonClicked:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction) onExportButtonClicked:(id)sender
{
    
    MFMailComposeViewController * picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:@"OAProto / test export"];
    
    /*
    NSArray *toRecipients = [NSArray arrayWithObject:@"first@example.com"];
    NSArray *ccRecipients = [NSArray arrayWithObjects:@"second@example.com", @"third@example.com", nil];
    NSArray *bccRecipients = [NSArray arrayWithObject:@"fourth@example.com"];
    
    [picker setToRecipients:toRecipients];
    [picker setCcRecipients:ccRecipients];
    [picker setBccRecipients:bccRecipients];
    */
    
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"export" ofType:@"xml"];
    
    [picker addAttachmentData:[self.wrapper xmlDataForUser:self.user] mimeType:@"text/plain" fileName:@"export.xml"];
    
    // Fill out the email body text
    NSString * emailBody = [NSString stringWithFormat:@"Export OAProto"];
    [picker setMessageBody:emailBody isHTML:NO];
    
    [self presentModalViewController:picker animated:YES];
    [picker release];}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        delegate = nil;
        // Custom initializati  on
    }
    return self;
}

/*
- (BOOL) shouldAutorotate
{
    return YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}
*/

- (void) updateEmailTextFieldColor
{
    BOOL emailIsValid = [DataWrapper NSStringIsValidEmail:self.emailTextField.text];
    [self.emailTextField.layer setBorderColor:emailIsValid ? [UIColor greenColor].CGColor : [UIColor redColor].CGColor];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.firstnameTextField.text = self.user.firstName;
    self.lastnameTextField.text = self.user.lastName;
    self.organisationTextField.text = self.user.organisation;
    self.emailTextField.text = self.user.email;
    
    self.selectButton.enabled = self.wrapper.currentUser != self.user;
    self.selectButton.alpha = self.selectButton.enabled ? 1.0f : 0.5f;
    
    if ( self.modalPresentationStyle == UIModalPresentationFormSheet ){
        // modal = création d'un nouveau compte.
        [[self exportButton] removeFromSuperview];
        if ( self.userIsFirstUser )
            [[self cancelButton] removeFromSuperview];
    } else {
        // pas modal = consultation d'un compte existant.
        [[self cancelButton] removeFromSuperview]; // parce qu'on a déjà un bouton "back" en navbar
        [self setTitle:self.titleLabel.text];
        [[self titleLabel] removeFromSuperview];
    }
    
    BOOL emailIsValid = [DataWrapper NSStringIsValidEmail:self.user.email];
    
    self.emailTextField.layer.cornerRadius=8.0f;
    self.emailTextField.layer.masksToBounds=YES;
    self.emailTextField.layer.borderWidth= 1.0f;
    
    [self updateEmailTextFieldColor];
    
    [self.saveButton setEnabled:emailIsValid];
    [self.saveButton setAlpha:self.saveButton.enabled ? 1 : 0.5];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotate
{
    return YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end

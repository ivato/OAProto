//
//  InfosViewController.m
//  OAProto
//
//  Created by Ivan Touzeau on 04/12/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "InfosViewController.h"
#import <MessageUI/MessageUI.h>

#define VIEWTAG_ISEALINK             100
#define VIEWTAG_DOMIMAIL             101
#define VIEWTAG_MATTMAIL             102
#define VIEWTAG_ISEAMAIL             103

#define DOMIMAIL                     @"Dominique Stutzmann <dominique.stutzmann@irht.cnrs.fr>"
#define MATTMAIL                     @"Matthieu Bonicel <matthieu.bonicel@bnf.fr>"
#define ISEAMAIL                     @"is&a bloom <contact@iseabloom.com>"
#define ISEALINK                     @"http://www.iseabloom.com"

@interface InfosViewController ()

@end

@implementation InfosViewController

- (IBAction) onLinkButtonClicked:(id)sender
{
    switch ( [(UIView *)sender tag] ) {
        case VIEWTAG_DOMIMAIL:
            [self sendMailTo:DOMIMAIL];
            break;
        case VIEWTAG_MATTMAIL:
            [self sendMailTo:MATTMAIL];
            break;
        case VIEWTAG_ISEAMAIL:
            [self sendMailTo:ISEAMAIL];
            break;
        case VIEWTAG_ISEALINK:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString: ISEALINK]];
            break;
        default:
            break;
    }
}


- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) sendMailTo:(NSString *)email
{
    MFMailComposeViewController * picker = [[[MFMailComposeViewController alloc] init] autorelease];
    picker.mailComposeDelegate = self;
    NSArray * toRecipients = [NSArray arrayWithObject:email];
    [picker setToRecipients:toRecipients];
    [self presentModalViewController:picker animated:YES];
}

- (IBAction) onDoneItemClicked:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    /*
    UITextView * tv = (UITextView *)[self.view viewWithTag:999];
    CGFloat txtHeight = [tv contentSize].height;
    
    CGRect frame;
    frame = [self.view viewWithTag:VIEWTAG_DOMIMAIL].frame;
    frame.origin.y = txtHeight + tv.frame.origin.y + 20;
    [[self.view viewWithTag:VIEWTAG_DOMIMAIL] setFrame:frame];
    frame = [self.view viewWithTag:VIEWTAG_MATTMAIL].frame;
    frame.origin.y = txtHeight + tv.frame.origin.y + 20;
    [[self.view viewWithTag:VIEWTAG_MATTMAIL] setFrame:frame];
    frame = [self.view viewWithTag:VIEWTAG_ISEAMAIL].frame;
    frame.origin.y = txtHeight + tv.frame.origin.y + 20;
    [[self.view viewWithTag:VIEWTAG_ISEAMAIL] setFrame:frame];
*/
    
    // Do any additional setup after loading the view from its nib.
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
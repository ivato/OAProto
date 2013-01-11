//
//  UsersViewController.m
//  OAProto
//
//  Created by Ivan Touzeau on 14/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "UsersViewController.h"

#import "OAProtoAppDelegate.h"
#import "DataWrapper.h"
#import "User.h"

#import "UserViewController.h"

@interface UsersViewController ()
{
    DataWrapper             * wrapper;
}

@property (nonatomic,assign)        DataWrapper     * wrapper;

@end

@implementation UsersViewController

@synthesize wrapper;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self ){
        self.wrapper = [(OAProtoAppDelegate *)[UIApplication sharedApplication].delegate wrapper];
    }
    return self;
}

- (id) initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void) onSaveButtonClicked:(User *)user
{
    [self.tableView reloadData];
    uint currentUserIndex = [self.wrapper.users indexOfObject:wrapper.currentUser];
    NSIndexPath * indexPath = [NSIndexPath indexPathForItem:currentUserIndex inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
}

- (void) onAddUserButtonClicked:(id)sender
{
    User * newUser = [wrapper createUser];
    UserViewController * userController = [[[UserViewController alloc] initWithUser:newUser] autorelease];
    [userController setDelegate:self];
    [userController setModalPresentationStyle:UIModalPresentationFormSheet];
    [userController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self.navigationController presentViewController:userController animated:YES completion:NULL];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    UIBarButtonItem * addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                              target:self
                                                                              action:@selector(onAddUserButtonClicked:)
                                 ];
    
    //self.navigationItem.rightBarButtonItem = addItem;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:addItem,self.editButtonItem,nil];
    [addItem release];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    uint currentUserIndex = [self.wrapper.users indexOfObject:wrapper.currentUser];
    NSIndexPath * indexPath = [NSIndexPath indexPathForItem:currentUserIndex inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.wrapper.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    [cell setBackgroundColor:[UIColor whiteColor]];
    
    User * user = [[wrapper users] objectAtIndex:indexPath.row];
    
    [[cell textLabel] setText:[NSString stringWithFormat:@"%@ %@",user.firstName,user.lastName]];
    [[cell detailTextLabel] setText:user.email];
    if ( user == self.wrapper.currentUser ){
        [cell setSelected:YES];
        [cell setHighlighted:YES];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User * user = [[wrapper users] objectAtIndex:indexPath.row];
    
    UserViewController * userController = [[[UserViewController alloc] initWithUser:user] autorelease];
    [userController setDelegate:self];
    [self.navigationController pushViewController:userController animated:YES];
}

#pragma mark - Rotation

- (BOOL) shouldAutorotate
{
    return YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


@end

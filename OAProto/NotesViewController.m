//
//  NotesViewController.m
//  OAProto
//
//  Created by Ivan Touzeau on 22/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "NotesViewController.h"
#import "EditViewController.h"
#import "OAProtoAppDelegate.h"
#import "DataWrapper.h"

#import "OpenAnnotation.h"
#import "Book.h"
#import "Page.h"
#import "Note.h"
#import "User.h"

@interface NotesViewController ()
{
    NSArray                 * dataSource;
    NSArray                 * indexTitles;
    EditViewController      * editController;
}

@property (nonatomic,retain)        NSArray                 * dataSource;
@property (nonatomic,retain)        NSArray                 * indexTitles;
@property (nonatomic,retain)        EditViewController      * editController;

@end

@implementation NotesViewController

@synthesize dataSource,editController,indexTitles;

- (void) dealloc
{
    [super dealloc];
    [editController release];
    [dataSource release];
    [indexTitles release];
}

/*
 - (id) initWithMode:(PageNavigationMode)mode
{
    switch (mode) {
        case PageNavigationModeBook:{
            [self setDataSource:[wrapper currentBook].
        }
        default:
            break;
    }
    
}
*/

- (id) initWithEditController:(EditViewController *)controller
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        [self setEditController:controller];
        //OAProtoAppDelegate * delegate = (OAProtoAppDelegate *)[[UIApplication sharedApplication] delegate];
        //DataWrapper * wrapper = delegate.wrapper;
        NSString * alphabet = @" abcdefghijklmnopqrstuvwxyz";
        NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        NSArray * temp = [editController.notes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
        NSMutableArray * final = [[NSMutableArray alloc] initWithCapacity:alphabet.length];
        NSMutableArray * indexes = [[NSMutableArray alloc] initWithCapacity:alphabet.length];
        
        for ( uint i=0; i<alphabet.length;i++ ){
            [final addObject:[NSMutableArray array]];
            [indexes addObject:[alphabet substringWithRange:NSMakeRange(i, 1)]];
        }
        for ( OpenAnnotation * note in temp ){
            if ( note.title != nil && note.title.length > 0 ){
                unichar firstChar = [note.title.lowercaseString characterAtIndex:0];
                for ( uint i=0;i<alphabet.length;i++){
                    unichar c = [alphabet characterAtIndex:i];
                    if ( c == firstChar ){
                        [[final objectAtIndex:i] addObject:note];
                    }
                }
            } else {
                [[final objectAtIndex:0] addObject:note];
            }
        }
        [self setDataSource:(NSArray *)final];
        [self setIndexTitles:(NSArray *)indexes];
        [final release];
        [indexes release];
                
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSArray *)[self.dataSource objectAtIndex:section] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if ( 44.0f * self.dataSource.count > self.tableView.bounds.size.height )
        return nil;
    return self.indexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index; //<yourSectionIndexForTheSectionForSectionIndexTitle >;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    [cell setBackgroundColor:[UIColor whiteColor]];
    
    OpenAnnotation * note = [(NSArray *)[self.dataSource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    [[cell textLabel] setText:(note.title == nil || note.title.length==0) ? NSLocalizedString(@"EDIT_NOTE_LIST_NOTITLE", nil) : note.title];
    [[cell detailTextLabel] setText:[note userDescription]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OpenAnnotation * note = [(NSArray *)[self.dataSource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [editController popoverDidSelectNote:note];
}

@end

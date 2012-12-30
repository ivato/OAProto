//
//  PanelsViewController.m
//  OAProto
//
//  Created by Ivan Touzeau on 15/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "PanelsViewController.h"
#import "OAProtoAppDelegate.h"
#import "UsersViewController.h"
#import "UserViewController.h"
#import "EditViewController.h"
#import "InfosViewController.h"

#import "UIImage+Resize.h"

#import "OpenAnnotation.h"
#import "OAShape.h"
#import "User.h"
#import "Book.h"
#import "Page.h"

#import "DataWrapper.h"

#import "FolderViewController.h"
#import "PSTCollectionView.h"
#import "CollectionViewCell.h"
#import "HeaderView.h"
#import "FooterView.h"
#import "PageViewCell.h"
#import "BookViewCell.h"
#import "HeaderPageViewCell.h"

#import <QuartzCore/QuartzCore.h>

#define ACTIVITYINDICATORVIEW_TAG       999
#define CONTENTVIEW_TAG                 997

enum HomeSection {
    kHomeSectionUnknown,
    kHomeSectionAllBooks,
    kHomeSectionMyBooks,
    kHomeSectionMyPages,
    kHomeSectionMyNotes
};
typedef enum HomeSection HomeSection;


@interface PanelsViewController()
{
    BOOL                          databaseReady;
    DataWrapper                 * wrapper;
    FolderViewController        * folderViewController;
    EditViewController          * editViewController;
    
    NSArray                     * contentData;
    
    HomeSection                   section;
    
    IBOutlet UIButton           * infosButton;
    
}

@property (nonatomic,retain)    IBOutlet UIButton       * infosButton;
@property (nonatomic,assign)    EditViewController      * editViewController;
@property (nonatomic,retain)    NSArray                 * contentData;
@property (nonatomic,assign)    BOOL                      databaseReady;
@property (nonatomic,assign)    DataWrapper             * wrapper;
@property (nonatomic,retain)    FolderViewController    * folderViewController;
@property (nonatomic,assign)    HomeSection               section;

@end

@implementation PanelsViewController

@synthesize infosButton, contentData,folderViewController,wrapper,databaseReady,section,editViewController;

static NSString * cellIdentifier            = @"TestCell";
static NSString * headerViewIdentifier      = @"Test Header View";
static NSString * footerViewIdentifier      = @"Test Footer View";

- (void) dealloc
{
    [super dealloc];
    [contentData release];
}

#pragma mark -
#pragma mark DataWrapper & UserViewController stuff

- (void) onSaveButtonClicked:(User *)user
{
    [self setSection:kHomeSectionAllBooks animated:YES];
}

- (void) displayUserInterface
{
    UserViewController * userController = [[[UserViewController alloc] initWithUser:nil] autorelease];
    [userController setDelegate:self];
    [userController setModalPresentationStyle:UIModalPresentationFormSheet];
    [userController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentViewController:userController animated:YES completion:NULL];
}

- (void) onSetupComplete
{
    databaseReady = YES;
    
    UIActivityIndicatorView * aiv = (UIActivityIndicatorView *)[self.view viewWithTag:ACTIVITYINDICATORVIEW_TAG];
    if ( aiv ){
        [aiv stopAnimating];
        [aiv removeFromSuperview];
    };
    
    [self setSection:section animated:YES];
    
    // next step is saving the first user
    if ( wrapper.users.count == 1 && wrapper.currentUser.email == nil ){
        [self displayUserInterface];
    }
}

- (void) setSection:(HomeSection)aSection animated:(BOOL)animated
{
    //HomeSection prevSection = self->section;
    section = aSection;
    
    PSTCollectionView * previousView = (PSTCollectionView *)[self.view viewWithTag:CONTENTVIEW_TAG];
    
    if ( previousView ){
        
        if ( animated ){
            [UIView animateWithDuration:0.2f
                             animations:^{
                                 [previousView setAlpha:0.0f];
                             }
                             completion:^(BOOL finishedCompletion){
                                 [previousView removeFromSuperview];
                                 [self setSection:aSection animated:YES];
                             }
             ];
        
        } else {
            [previousView removeFromSuperview];
            [self setSection:aSection animated:NO];
        }
        
    
    } else {
        
        UIView * contentView = nil;
        
        if ( section == kHomeSectionAllBooks || section == kHomeSectionMyBooks || section == kHomeSectionMyPages )
        {
            //
            PSTCollectionViewFlowLayout * flowLayout = [[PSTCollectionViewFlowLayout alloc] init];
            [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
            [flowLayout setItemSize:CGSizeMake(200, 280)];
            [flowLayout setHeaderReferenceSize:CGSizeMake(768, 55)];
            [flowLayout setFooterReferenceSize:CGSizeMake(500, 1)];
            [flowLayout setMinimumInteritemSpacing:20];
            [flowLayout setMinimumLineSpacing:20];
            [flowLayout setSectionInset:UIEdgeInsetsMake(0, 20, 0, 20)];
            CGRect contentFrame = self.view.frame;
            contentFrame.origin.y += 50;
            contentFrame.size.height -= (50+39); // 39 being the position of infosButton.
            
            PSTCollectionView * collectionView = [[PSTCollectionView alloc] initWithFrame:contentFrame collectionViewLayout:flowLayout];
            [collectionView setTag:CONTENTVIEW_TAG];
            [collectionView setDelegate:self];
            [collectionView setDataSource:self];
            [collectionView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
            [collectionView setBackgroundColor:[UIColor clearColor]];
            [flowLayout release];            
            
            if ( section == kHomeSectionAllBooks ){
                [collectionView registerClass:[BookViewCell class] forCellWithReuseIdentifier:cellIdentifier];
                [self setContentData:[NSArray arrayWithObject:[wrapper books]]];
            }
            else if ( section == kHomeSectionMyBooks ){
                [collectionView registerClass:[BookViewCell class] forCellWithReuseIdentifier:cellIdentifier];
                [self setContentData:[NSArray arrayWithObject:[wrapper booksWithNotesForUser:wrapper.currentUser]]];
            }
            else if ( section == kHomeSectionMyPages ){
                [collectionView registerClass:[PageViewCell class] forCellWithReuseIdentifier:cellIdentifier];
                [collectionView registerClass:[HeaderPageViewCell class] forSupplementaryViewOfKind:PSTCollectionElementKindSectionHeader withReuseIdentifier:headerViewIdentifier];
                
                NSMutableArray * userPages = [NSMutableArray array];
                NSArray * allUserPages = [wrapper pagesWithNotesForUser:wrapper.currentUser];
                for ( Book * book in [wrapper booksWithNotesForUser:wrapper.currentUser] ){
                    NSMutableArray * pages = [NSMutableArray array];
                    for ( Page * page in allUserPages ){
                        if ( page.book == book )
                            [pages addObject:page];
                    }
                    [userPages addObject:pages];
                }
                [self setContentData:userPages];
            }
            contentView = collectionView;
        }
        else if ( section == kHomeSectionMyNotes )
        {
            CGRect contentFrame = self.view.frame;
            contentFrame.origin.y += 100;
            contentFrame.size.height -= 100;
            UILabel * label = [[UILabel alloc] initWithFrame:contentFrame];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setTextAlignment:NSTextAlignmentCenter];
            [label setTextColor:[UIColor whiteColor]];
            [label setText:NSLocalizedString(@"WIP", nil)];
            [label setTag:CONTENTVIEW_TAG];
            contentView = label;
        }
        
        if ( animated ){
            [contentView setAlpha:0.0f];
            [self.view addSubview:contentView];
            [UIView animateWithDuration:0.2f animations:^{
                [contentView setAlpha:1.0f];
            }];
        } else {
            [self.view addSubview:contentView];
        }
        [contentView release];
    }
}

#pragma mark -
#pragma mark FolderView stuff


- (void) onFoldedViewWillOpen:(UIView *)view
{
    [self.navigationItem.titleView setUserInteractionEnabled:NO];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
}

- (void) onFoldedViewDidOpen:(UIView *)view
{
    
}

- (void) onFoldedViewWillCloseAnimated:(BOOL)animated
{
    
}

- (void) onFoldedViewDidCloseAnimated:(BOOL)animated
{
    [self.navigationItem.titleView setUserInteractionEnabled:YES];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [folderViewController release];
    self->folderViewController = nil;
}

- (void) onItemSelected:(id)item
{
    Page * page = (Page *) item;
    [wrapper setCurrentPage:page];
    
    EditViewController * ec = [[EditViewController alloc] initWithNibName:@"EditViewController" bundle:nil];
    [self setEditViewController:ec];
    [ec setDelegate:self];
    [editViewController setPage:page];
}

#pragma mark - EditViewController delegate

- (void) onImageResized
{
    [editViewController setDelegate:nil];
    [self setTitle:NSLocalizedString(@"HOME_TITLE", nil)];
    [self.navigationItem setTitle:NSLocalizedString(@"HOME_TITLE", nil)];
    [self.navigationController pushViewController:editViewController animated:YES];
    [editViewController release];
    
}

#pragma mark - PSUICollectionView stuff

- (NSInteger)numberOfSectionsInCollectionView:(PSTCollectionView *)collectionView {
    return self.contentData.count;
}

- (NSInteger)collectionView:(PSTCollectionView *)collectionView numberOfItemsInSection:(NSInteger)aSection {
    return [(NSArray *)[self.contentData objectAtIndex:aSection] count];
}

- (void) collectionView:(PSTCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( section==kHomeSectionAllBooks || section==kHomeSectionMyBooks )
    {
        BookViewCell * cell = (BookViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        CGPoint position = cell.frame.origin;
        position.x += collectionView.frame.origin.x + cell.frame.size.width/2;
        position.y += collectionView.frame.origin.y + cell.frame.size.height - 10;
        Book * book = [(NSArray *)[self.contentData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        FolderViewController * fvc = [[FolderViewController alloc] initWithController:self position:position book:book];
        fvc.delegate = self;
        [self setFolderViewController:fvc];
        [fvc release];
    }
    else if ( section==kHomeSectionMyPages )
    {
        Page * page = [(NSArray *)[self.contentData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        PageViewCell * cell = (PageViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [cell displayLoading:YES];
        [wrapper setCurrentPage:page];
        
        float delayInSeconds = 0.01f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            EditViewController * ec = [[EditViewController alloc] initWithNibName:@"EditViewController" bundle:nil];
            [self setEditViewController:ec];
            [ec setDelegate:self];
            [ec setPage:page];
        });
        
    }
}

- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( section==kHomeSectionAllBooks || section==kHomeSectionMyBooks)
    {
        BookViewCell * cell = (BookViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        [cell updateForBook:[(NSArray *)[self.contentData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
        return cell;
    }
    else if ( section==kHomeSectionMyPages)
    {
        PageViewCell * cell = (PageViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        Page * page = [(NSArray *)[self.contentData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        [cell updateForPage:page thumbnail:[DataWrapper thumbnailForPage:page]];
        return cell;
    }
    return nil;
}

- (PSTCollectionReusableView *)collectionView:(PSTCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
	NSString * identifier = nil;
    if ([kind isEqualToString:PSTCollectionElementKindSectionHeader]) {
        identifier = headerViewIdentifier;
        if ( section == kHomeSectionMyPages ){
            HeaderPageViewCell * cell = (HeaderPageViewCell *)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
            Page * page = [(NSArray *)[self.contentData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            [cell updateForBook:page.book];
            return (PSTCollectionReusableView *)cell;
        }
    }
    return nil;
}

#pragma mark -

- (IBAction) onInfosButtonClicked:(id)sender
{
    InfosViewController * infosController = [[[InfosViewController alloc] init] autorelease];
    infosController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve; //UIModalTransitionStyleFlipHorizontal;
    //infosController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:infosController animated:YES];
}

- (void) onTabsClicked:(id)sender
{
    if ( self.folderViewController ){
        [folderViewController closeAnimated:YES];
    } else {
        int index = [(UISegmentedControl *)sender selectedSegmentIndex];
        [self setSection:(index==0 ? kHomeSectionAllBooks : index==1 ? kHomeSectionMyBooks : index == 2 ? kHomeSectionMyPages : kHomeSectionMyNotes) animated:YES];
    }
}

- (void) onNBUserInfoButtonClicked:(id)sender
{
    UsersViewController * usersController = [[UsersViewController alloc] initWithNibName:@"UsersViewController" bundle:nil];
    [usersController setTitle:NSLocalizedString(@"HOME_NB_USERS", nil)];
    [self.navigationController pushViewController:usersController animated:YES];
    [usersController release];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        OAProtoAppDelegate * delegate = (OAProtoAppDelegate *) [[UIApplication sharedApplication] delegate];
        wrapper = delegate.wrapper;
        [wrapper setDelegate:self];
        
        databaseReady = [wrapper initDatabase];
        
        if ( databaseReady == NO ){
            UIActivityIndicatorView * aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [aiv setTag:ACTIVITYINDICATORVIEW_TAG];
            [self.view addSubview:aiv];
            [aiv startAnimating];
            [aiv release];
        }
    }
    return self;
}

- (void) viewDidLoad
{
    
    UISegmentedControl * segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                                     NSLocalizedString(@"HOME_NB_ALLBOOKS", nil),
                                                                                     NSLocalizedString(@"HOME_NB_MYBOOKS", nil),
                                                                                     NSLocalizedString(@"HOME_NB_MYPAGES", nil),
                                                                                     NSLocalizedString(@"HOME_NB_MYNOTES", nil),
                                                                                     nil]
                                           ];
    segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [segmentControl setSelectedSegmentIndex:0];
    [segmentControl addTarget:self action:@selector(onTabsClicked:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentControl;
    [segmentControl release];
    
    UIBarButtonItem * u = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"HOME_NB_USERS",nil)
                                                           style:UIBarButtonItemStylePlain
                                                          target:self

                                                          action:@selector(onNBUserInfoButtonClicked:)
                           ];
    
    self.navigationItem.rightBarButtonItem = u;
    [u release];

    [super viewDidLoad];
    
}

- (void) viewDidUnload
{
    [super viewDidUnload];
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.titleView = nil;
    
}

- (void) viewDidDisappear:(BOOL)animated
{
    UISegmentedControl * segmentControl = (UISegmentedControl *)[self.navigationItem titleView];
    [segmentControl setEnabled:YES];
    [folderViewController release];
    folderViewController = nil;
    [super viewDidDisappear:animated];    
}

- (void) viewDidAppear:(BOOL)animated
{
    if ( databaseReady && wrapper.currentUser.email == nil )
        [self displayUserInterface];
    [super viewDidAppear:animated];
}

- (void) viewWillAppear:(BOOL)animated
{
    if ( databaseReady ){
        [self setSection:self->section == kHomeSectionUnknown ? kHomeSectionAllBooks : section animated:self->section == kHomeSectionUnknown];
    }
    
    [super viewWillAppear:animated];
}

- (BOOL) shouldAutorotate
{
    return YES;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ( self.folderViewController )
        [self.folderViewController closeAnimated:NO];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end

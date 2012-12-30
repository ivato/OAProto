//
//  FolderViewController.m
//  OAProto
//
//  Created by Ivan Touzeau on 09/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "FolderViewController.h"
#import "UIOpaqueView.h"
#import "DataWrapper.h"

#import "PSTCollectionView.h"
#import "CollectionViewCell.h"
#import "PageViewCell.h"

#import "HeaderView.h"
#import "FooterView.h"

#import "Book.h"
#import "Page.h"

#import <QuartzCore/QuartzCore.h>

#define ARROW_HEIGHT        25.0f // 25.0f
#define ARROW_WIDTH         50.0f // 50.0f
#define SHADOW_RADIUS       50.0f
#define BOTTOM_INSET        20.0f

#define ANIMATION_DURATION  0.4f

@interface FolderViewController ()
{
    CALayer                     * topLayer;
    CALayer                     * bottomLayer;
    CAShapeLayer                * topLayerMask;
    CALayer                     * bottomLayerMask;
    CALayer                     * baLayer;
    CAShapeLayer                * baLayerMask;
    
    CAShapeLayer                * topLine;
    CAShapeLayer                * bottomLine;
    
    CALayer                     * bgLayer;
    CALayer                     * sLayer;
    CALayer                     * sLayer2;
    
    CGFloat                       startYPosition;
    CGFloat                       endYPosition;
    CGFloat                       height;
    
    BOOL                          isClosing;
    BOOL                          open;
    
    UIViewController            * controller;
    PSTCollectionView           * contentView;
        
}

@property (nonatomic,retain)    PSTCollectionView           * contentView;
@property (nonatomic,retain)    Book                        * book;
@property (nonatomic,retain)    NSArray                     * pages;
@property (nonatomic,retain)    NSMutableArray              * thumbnails;

@property (nonatomic,assign)    UIViewController            * controller;

@end

@implementation FolderViewController

@synthesize contentView,book,pages,thumbnails,controller;

static NSString * cellIdentifier            = @"Test Cell";
static NSString * headerViewIdentifier      = @"Test Header View";
static NSString * footerViewIdentifier      = @"Test Footer View";

@synthesize delegate;

- (void) dealloc
{
    
    [contentView release];
    self->contentView = nil;
    
    topLayer.mask = nil;
    bottomLayer.mask = nil;
    
    [book release];
    [pages release];
    [thumbnails release];
    thumbnails = nil;
    [super dealloc];
}

- (id) initWithController:(id)aController position:(CGPoint)position book:(Book *)aBook
{
    self = [super initWithNibName:nil bundle:nil];
    
    if ( self ){
        
        [self setController:(UIViewController *)aController];
        
        [self setBook:aBook];
        
        height = 270;
        
        [self setPages:[self.book.pages.allObjects sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            return [[(Page *)a index] compare:[(Page *)b index]];
        }]];
        
        NSMutableArray * t = [[NSMutableArray alloc] initWithCapacity:self.pages.count];
        [self setThumbnails:t];
        [t release];
        UIImage * defaultImage = [UIImage imageNamed:@"temp_200x200.png"];
        for ( Page * page in self.pages){
            [thumbnails addObject:defaultImage];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                // attention, le numéro de la page n'est pas son index dans la table.
                NSIndexPath * indexPath = [NSIndexPath indexPathForItem:[self.pages indexOfObject:page] inSection:0];
                UIImage * thumbnail = [DataWrapper thumbnailForPage:page];
                [self.thumbnails setObject:thumbnail atIndexedSubscript:indexPath.row];
                PageViewCell * cell = (PageViewCell *)[contentView cellForItemAtIndexPath:indexPath];
                [cell updateForPage:page thumbnail:thumbnail];
            });
        };
        
        CGRect frame = controller.view.frame;
        
        float scale = [[UIScreen mainScreen] scale];
        UIGraphicsBeginImageContextWithOptions(frame.size, true, scale);
        CGContextRef imageContext = UIGraphicsGetCurrentContext();
        [controller.view.layer renderInContext:imageContext];
        UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //frame.origin.y = 0.0;
        UIOpaqueView * v = [[UIOpaqueView alloc] initWithFrame:frame];
        [self setView:v];
        [v release];
        
        startYPosition = position.y;
        endYPosition = fminf(position.y, frame.size.height - BOTTOM_INSET - height - ARROW_HEIGHT);
        
        PSTCollectionViewFlowLayout * flowLayout = [[PSTCollectionViewFlowLayout alloc] init];
        
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        [flowLayout setItemSize:CGSizeMake(200, 205)];
        [flowLayout setHeaderReferenceSize:CGSizeZero];
        [flowLayout setFooterReferenceSize:CGSizeZero];
        [flowLayout setMinimumInteritemSpacing:20];
        [flowLayout setMinimumLineSpacing:20];
        //[self.flowLayout setSectionInset:UIEdgeInsetsMake( 50, 10, 5, 10)];
        [flowLayout setSectionInset:UIEdgeInsetsMake( 0, 10, 0, 10)];
        
        PSTCollectionView * cv = [[PSTCollectionView alloc] initWithFrame:CGRectMake( 0, startYPosition+ARROW_HEIGHT, frame.size.width,height) collectionViewLayout:flowLayout];
        [flowLayout release];
        
        [self setContentView:cv];
        [cv release];
        
        [contentView setDelegate:self];
        [contentView setDataSource:self];
        [contentView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [contentView setBackgroundColor:[UIColor clearColor]];
        
        [contentView registerClass:[PageViewCell class] forCellWithReuseIdentifier:cellIdentifier];
                
        [controller.view addSubview:self.view];
        
        self.view.layer.frame = frame;
        self.view.layer.masksToBounds = YES;
        
        topLayer = [CALayer layer];
        topLayerMask = [CAShapeLayer layer];
        bottomLayer = [CALayer layer];
        bottomLayerMask = [CALayer layer];
        baLayer = [CALayer layer];
        baLayerMask = [CAShapeLayer layer];
        
        topLayer.contents = (id)image.CGImage;
        bottomLayer.contents = (id)image.CGImage;
        baLayer.contents = (id)image.CGImage;
        topLayer.frame = frame;
        bottomLayer.frame = frame;
        baLayer.frame = frame;
        topLayerMask.frame = frame;
        baLayerMask.frame = frame;
        topLayerMask.fillColor = [UIColor blackColor].CGColor;
        bottomLayerMask.backgroundColor = [UIColor blackColor].CGColor;
        baLayerMask.fillColor = [UIColor blackColor].CGColor;
        
        //
        CGMutablePathRef pathRef = CGPathCreateMutable();
        CGPathMoveToPoint(pathRef, NULL, 0, 0);
        CGPathAddLineToPoint(pathRef, NULL, frame.size.width, 0);
        CGPathAddLineToPoint(pathRef, NULL, frame.size.width, startYPosition+ARROW_HEIGHT);
        CGPathAddLineToPoint(pathRef, NULL, position.x+ARROW_WIDTH/2, startYPosition+ARROW_HEIGHT);
        CGPathAddLineToPoint(pathRef, NULL, position.x, startYPosition);
        CGPathAddLineToPoint(pathRef, NULL, position.x-ARROW_WIDTH/2, startYPosition+ARROW_HEIGHT);
        CGPathAddLineToPoint(pathRef, NULL, 0, startYPosition+ARROW_HEIGHT);
        CGPathCloseSubpath(pathRef);
        topLayerMask.path = pathRef;
        CGPathRelease(pathRef);
        
        //
        CGMutablePathRef baPathRef = CGPathCreateMutable();
        CGPathMoveToPoint(baPathRef, NULL, position.x-ARROW_WIDTH/2, startYPosition+ARROW_HEIGHT);
        CGPathAddLineToPoint(baPathRef, NULL, position.x, startYPosition);
        CGPathAddLineToPoint(baPathRef, NULL, position.x+ARROW_WIDTH/2, startYPosition+ARROW_HEIGHT);
        CGPathCloseSubpath(baPathRef);
        baLayerMask.path = baPathRef;
        CGPathRelease(baPathRef);
        
        bottomLayerMask.frame = CGRectMake(0,startYPosition+ARROW_HEIGHT,frame.size.width,frame.size.height-startYPosition);

        topLayer.mask = topLayerMask;
        bottomLayer.mask = bottomLayerMask;
        baLayer.mask = baLayerMask;
        
        bgLayer = [CALayer layer];
        bgLayer.anchorPoint = CGPointZero;
        bgLayer.frame = CGRectMake(0,endYPosition,frame.size.width,height+ARROW_HEIGHT);
        bgLayer.backgroundColor = [UIColor scrollViewTexturedBackgroundColor].CGColor;
        
        CALayer * subLayer = [CALayer layer];
        subLayer.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f].CGColor;
        subLayer.frame = frame;
        [bgLayer addSublayer:subLayer];
        
        topLine = [CAShapeLayer layer];
        topLine.frame = frame;
        CGMutablePathRef topLinePath = CGPathCreateMutable();
        CGPathMoveToPoint(topLinePath, NULL, 0, startYPosition+ARROW_HEIGHT);
        CGPathAddLineToPoint(topLinePath, NULL, position.x-ARROW_WIDTH/2, startYPosition+ARROW_HEIGHT);
        CGPathAddLineToPoint(topLinePath, NULL, position.x, startYPosition);
        CGPathAddLineToPoint(topLinePath, NULL, position.x+ARROW_WIDTH/2, startYPosition+ARROW_HEIGHT);
        CGPathAddLineToPoint(topLinePath, NULL, frame.size.width, startYPosition+ARROW_HEIGHT);
        topLine.path = topLinePath;
        topLine.strokeColor = [UIColor whiteColor].CGColor;
        [topLayer addSublayer:topLine];
        
        bottomLine = [CAShapeLayer layer];
        bottomLine.frame = frame;
        CGMutablePathRef bottomLinePath = CGPathCreateMutable();
        CGPathMoveToPoint(bottomLinePath, NULL, 0, startYPosition+0.25f+ARROW_HEIGHT);
        CGPathAddLineToPoint(bottomLinePath, NULL, frame.size.width, startYPosition+0.25f+ARROW_HEIGHT);
        bottomLine.strokeColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
        bottomLine.path = bottomLinePath;
        [bottomLayer addSublayer:bottomLine];
        
        topLine.opacity = bottomLine.opacity = 0.0f;
        
        CGPathRelease(topLinePath);
        CGPathRelease(bottomLinePath);
        
        sLayer = [CALayer layer];
        sLayer.anchorPoint = CGPointZero;
        sLayer.bounds = CGRectMake(0,0,frame.size.width,SHADOW_RADIUS+ARROW_HEIGHT);
        sLayer.contents = (id)[UIImage imageNamed:@"gradient_down_10x100.png"].CGImage;
        
        sLayer2 = [CALayer layer];
        sLayer2.anchorPoint = CGPointMake(0,1);
        sLayer2.bounds = CGRectMake(0,0,frame.size.width, SHADOW_RADIUS+ARROW_HEIGHT);
        sLayer2.contents = (id)[UIImage imageNamed:@"gradient_up_10x100.png"].CGImage;
        
        sLayer.position = CGPointMake(0,endYPosition);
        sLayer2.position = CGPointMake(0,endYPosition+height+ARROW_HEIGHT*2);
        
        sLayer.opacity = sLayer2.opacity = 0.5f;
        
        [self.view.layer addSublayer:bgLayer];
        [self.view.layer addSublayer:sLayer];
        [self.view.layer addSublayer:sLayer2];
        
        NSString * bookDescription = [NSString stringWithFormat:@"%@, %@, %@ / %@",
                                      self.book.city,
                                      self.book.source,
                                      self.book.headline,
                                      self.book.name
                                      ];
        
        
        CGFloat fontSize = 16.0f;        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 748, 40)];
        [label setFont:[UIFont systemFontOfSize:fontSize]];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor whiteColor]];
        [label setText:bookDescription];
        [label setShadowColor:[UIColor colorWithWhite:0 alpha:1]];
        [label setShadowOffset:CGSizeMake(-1, -1)];
        [label setUserInteractionEnabled:NO];
        [self.contentView addSubview:label];
        [label release];
        
        [self.view.layer addSublayer:topLayer];
        [self.view.layer addSublayer:baLayer];
        [self.view.layer addSublayer:bottomLayer];
        
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.x = 0.0f;
        contentFrame.origin.y = startYPosition+ARROW_HEIGHT;
        contentFrame.size.width = frame.size.width;
        contentFrame.size.height = 10.0f;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.contentView.frame = contentFrame;
        [self.contentView setDelaysContentTouches:NO];
        
        [self.view addSubview:contentView];

    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [delegate onFoldedViewWillOpen:self.contentView];
    open = YES;
    [CATransaction begin];
    [CATransaction setAnimationDuration:ANIMATION_DURATION];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [CATransaction setCompletionBlock:^{
        [delegate onFoldedViewDidOpen:self.contentView];
    }];
    
    topLayer.position = CGPointMake(topLayer.position.x, topLayer.position.y+(endYPosition-startYPosition));
    bottomLayer.position = CGPointMake(bottomLayer.position.x, bottomLayer.position.y+(endYPosition-startYPosition)+height);
    baLayer.position = CGPointMake(baLayer.position.x,baLayer.position.y+(endYPosition-startYPosition)+height+ARROW_HEIGHT*2); // *2 to make it disappear faster.
    topLine.opacity = bottomLine.opacity = 1.0f;
    [CATransaction commit];
    
    CGRect contentFrame = self.contentView.frame;
    contentFrame.origin.y = endYPosition+ARROW_HEIGHT;
    contentFrame.size.height = height;
    
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^{
                         self.contentView.frame = contentFrame;
                     }
                     completion:^(BOOL finished){
                     }
     ];
    
}

- (void) closeAnimated:(BOOL)animated
{
    
    if ( isClosing || !open )
        return;
    
    isClosing = YES;
    [delegate onFoldedViewWillCloseAnimated:animated];
    
    if ( !animated ){
        [self.view removeFromSuperview];
        [delegate onFoldedViewDidCloseAnimated:NO];
        open = NO;
        return;
    }
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:ANIMATION_DURATION];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    topLayer.position = CGPointMake(topLayer.position.x, topLayer.position.y-(endYPosition-startYPosition));
    bottomLayer.position = CGPointMake(bottomLayer.position.x, bottomLayer.position.y-(endYPosition-startYPosition+height));
    baLayer.position = CGPointMake(baLayer.position.x, baLayer.position.y-(endYPosition-startYPosition+height+ARROW_HEIGHT*2));
    topLine.opacity = bottomLine.opacity = 0.0f;
    [CATransaction commit];
    
    [UIView animateWithDuration:ANIMATION_DURATION delay:0 options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         CGRect contentFrame = self.contentView.frame;
                         contentFrame.origin.y = startYPosition+ARROW_HEIGHT;
                         contentFrame.size.height = 1;
                         [contentView setFrame:contentFrame];
                     }
                     completion:^(BOOL finished){
                         [self.view removeFromSuperview];
                         [delegate onFoldedViewDidCloseAnimated:YES];
                         open = NO;
                     }
     ];
    
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self closeAnimated:YES];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self closeAnimated:NO];
}

- (BOOL) shouldAutorotate
{
    return YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self closeAnimated:YES];
}

#pragma mark -
#pragma mark PSUICollectionView stuff

- (PageViewCell *) cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return (PageViewCell *)[self.contentView cellForItemAtIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInCollectionView:(PSTCollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(PSTCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return section == 0 ? self.book.pages.count : 0;
}

- (void) collectionView:(PSTCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PageViewCell * cell = (PageViewCell *)[self.contentView cellForItemAtIndexPath:indexPath];
    [cell displayLoading:YES];
    float delayInSeconds = 0.01;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[self delegate] onItemSelected:[self.pages objectAtIndex:indexPath.row]];
    });
}

- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    PSTCollectionViewCell * cell = (PSTCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    [(PageViewCell *)cell updateForPage:[self.pages objectAtIndex:indexPath.row]
                              thumbnail:[[self thumbnails] objectAtIndex:indexPath.row]
     ];
    
    return cell;
}

- (PSTCollectionReusableView *)collectionView:(PSTCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
	NSString * identifier = nil;
	
	if ([kind isEqualToString:PSTCollectionElementKindSectionHeader]) {
		identifier = headerViewIdentifier;
	} else if ([kind isEqualToString:PSTCollectionElementKindSectionFooter]) {
		identifier = footerViewIdentifier;
	}
    PSTCollectionReusableView * supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
	
    // TODO Setup view
	
    return supplementaryView;
}

@end

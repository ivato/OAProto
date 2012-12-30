//
//  FolderViewController.h
//  OAProto
//
//  Created by Ivan Touzeau on 09/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTCollectionView.h"

@class PageViewCell;

@protocol FolderViewDelegate <NSObject>

@optional

- (void) onFoldedViewWillOpen:(UIView *)view;
- (void) onFoldedViewDidOpen:(UIView *)view;
- (void) onFoldedViewWillCloseAnimated:(BOOL)animated;
- (void) onFoldedViewDidCloseAnimated:(BOOL)animated;
- (void) onItemSelected:(id)item;

- (void) onAddButtonClicked:(id)sender;

@end

@class Book;

@interface FolderViewController : UIViewController <PSTCollectionViewDataSource, PSTCollectionViewDelegate>
{
    id <FolderViewDelegate>         delegate;
}

- (id)              initWithController:(id)aController position:(CGPoint)position book:(Book *)aBook;

- (void)            closeAnimated:(BOOL)animated;

- (PageViewCell *)  cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic,retain)    id              delegate;

@end

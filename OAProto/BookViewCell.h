//
//  BookViewCell.h
//  OAProto
//
//  Created by Ivan Touzeau on 11/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTCollectionView.h"

@class Book;

@interface BookViewCell : PSTCollectionViewCell

- (void) updateForBook:(Book *)book;

@end

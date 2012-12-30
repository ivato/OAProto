//
//  HeaderPageViewCell.h
//  OAProto
//
//  Created by Ivan Touzeau on 25/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "PSTCollectionView.h"

@class Book;

@interface HeaderPageViewCell : PSTCollectionReusableView

- (void) updateForBook:(Book *)book;

@end

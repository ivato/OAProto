//
//  PageView.h
//  OAProto
//
//  Created by Ivan Touzeau on 10/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PSTCollectionView.h"

@class Page;

@interface PageViewCell : PSTCollectionViewCell

- (void) updateForPage:(Page *)page thumbnail:(UIImage *)thumbnail;

- (void) displayLoading:(BOOL)display;

@end

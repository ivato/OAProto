//
//  HeaderPageViewCell.m
//  OAProto
//
//  Created by Ivan Touzeau on 25/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "HeaderPageViewCell.h"
#import "Book.h"

@implementation HeaderPageViewCell

- (void) updateForBook:(Book *)book
{
    UILabel * label = (UILabel *)[self viewWithTag:999];
    [label setText:[NSString stringWithFormat:@"%@, %@, %@",book.city,book.source,book.headline]];
    UILabel * label2 = (UILabel *)[self viewWithTag:998];
    [label2 setText:book.name];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.1]];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20,5,700,30)];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont boldSystemFontOfSize:18.0f];
        label.tag = 999;
        label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
        label.shadowOffset = CGSizeMake(-1,1);
        [self addSubview:label];
        [label release];
        
        UILabel * label2 = [[UILabel alloc] initWithFrame:CGRectMake(20,25,700,30)];
        label2.backgroundColor = [UIColor clearColor];
        label2.textColor = [UIColor whiteColor];
        label2.font = [UIFont systemFontOfSize:16.0f];
        label2.tag = 998;
        label2.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
        label2.shadowOffset = CGSizeMake(-1,1);
        [self addSubview:label2];
        [label2 release];
        
    }
    return self;
}

@end

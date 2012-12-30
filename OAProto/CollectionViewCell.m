//
//  CollectionViewCell.m
//  FlowLayoutNoNIB
//
//  Created by Beau G. Bolle on 2012.10.29.
//
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self setBackgroundColor:[UIColor clearColor]];
		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 205, CGRectGetWidth(self.bounds), 60)];
		[label setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
		[label setTag:123];
        [label setFont:[UIFont boldSystemFontOfSize:18.0f]];
		[label setTextColor:[UIColor whiteColor]];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:2];
        label.layer.shadowColor = [UIColor blackColor].CGColor;
        label.layer.shadowRadius = 2.0f;
        label.layer.shadowOpacity = 0.9f;
        label.layer.shadowOffset = CGSizeZero;
        
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
		[imageView setTag:124];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        /*
        imageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 200, 200)].CGPath;
        imageView.layer.shadowColor = [UIColor blackColor].CGColor;
        imageView.layer.shadowRadius = 12.0f;
        imageView.layer.shadowOpacity = 0.7f;
         imageView.layer.shouldRasterize = YES;
        */
        [self addSubview:imageView];
        
		[self addSubview:label];
        
	}
	return self;
}

@end

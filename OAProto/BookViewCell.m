//
//  BookViewCell.m
//  OAProto
//
//  Created by Ivan Touzeau on 11/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "BookViewCell.h"
#import "Book.h"
#import "DataWrapper.h"
#import "UIImage+Resize.h"

@interface BookViewCell()
{
    CALayer             * imageLayer;
    CATextLayer         * textLayer;
}

@property (nonatomic,assign)        CALayer         * imageLayer;
@property (nonatomic,assign)        CATextLayer     * textLayer;

@end

@implementation BookViewCell

@synthesize imageLayer,textLayer;

#define MAX_IMAGE_SIZE              200.0f

- (void) dealloc
{
    [super dealloc];
}

- (void) setHighlighted:(BOOL)highlighted
{
    [[self viewWithTag:124] setAlpha:highlighted ? 0.7f : 1.0f];
}

- (void) updateForBook:(Book *)book
{
    
    NSString * headline = [NSString stringWithFormat:@"%@, %@, %@",book.city,book.source,book.headline];
    
    UIImage * thumbnail = [DataWrapper thumbnailForBook:book];
    CGSize newSize = CGSizeZero;
    if ( thumbnail.size.width/thumbnail.size.height > 1.0f ){
        newSize.width = MAX_IMAGE_SIZE;
        newSize.height = thumbnail.size.height / (thumbnail.size.width/newSize.width);
    } else {
        newSize.height = MAX_IMAGE_SIZE;
        newSize.width = thumbnail.size.width / (thumbnail.size.height/newSize.height);
    }
    UIImageView * imageView = (UIImageView *)[self viewWithTag:124];
    [imageView setImage:thumbnail];
        
    [(UILabel *)[self viewWithTag:123] setText:headline];
    
    UILabel * nameLabel = (UILabel *)[self viewWithTag:143];
    [nameLabel setText:book.name];
    [nameLabel sizeToFit];
    CGRect nameFrame = nameLabel.frame;
    nameFrame.size.width = CGRectGetWidth(self.bounds);
    nameLabel.frame = nameFrame;
    nameFrame.origin = CGPointApplyAffineTransform(nameFrame.origin, CGAffineTransformMakeTranslation(-1, 1));
    
}



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self ){
        
		UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 190, CGRectGetWidth(self.bounds), 40)];
		[label setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
		[label setTag:123];
        [label setFont:[UIFont boldSystemFontOfSize:16.0f]];
		[label setTextColor:[UIColor whiteColor]];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:1];
        [label setShadowColor:[UIColor colorWithWhite:0 alpha:0.5]];
        [label setShadowOffset:CGSizeMake(-1, -1)];
        
		UILabel * nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 225, CGRectGetWidth(self.bounds), 40)];
		[nameLabel setTag:143];
        [nameLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
		[nameLabel setTextColor:[UIColor whiteColor]];
		[nameLabel setBackgroundColor:[UIColor clearColor]];
		[nameLabel setTextAlignment:NSTextAlignmentCenter];
        [nameLabel setNumberOfLines:2];
        [nameLabel setShadowColor:[UIColor colorWithWhite:0 alpha:0.5]];
        [nameLabel setShadowOffset:CGSizeMake(-1, -1)];
        
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, MAX_IMAGE_SIZE, MAX_IMAGE_SIZE)];
		[imageView setTag:124];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        
        [self addSubview:imageView];
		[self addSubview:label];
        [self addSubview:nameLabel];
        
        [label release];
        [nameLabel release];
        [imageView release];
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

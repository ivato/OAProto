//
//  PageView.m
//  OAProto
//
//  Created by Ivan Touzeau on 10/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "PageViewCell.h"
#import "DataWrapper.h"
#import "Page.h"

#import <QuartzCore/QuartzCore.h>

#define USE_SHADOW          YES
#define MAX_IMAGE_SIZE      150.0f

@interface PageViewCell()
{
    CALayer             * imageLayer;
    CATextLayer         * textLayer;
    CGRect                imageRect;
}

@property (nonatomic,assign)        CALayer         * imageLayer;
@property (nonatomic,assign)        CATextLayer     * textLayer;
@property (nonatomic,assign)        CGRect            imageRect;

@end

@implementation PageViewCell

@synthesize imageLayer,textLayer,imageRect;

- (void) dealloc
{
    [super dealloc];
}

- (void) setHighlighted:(BOOL)highlighted
{
    self.imageLayer.opacity = highlighted ? 0.7f : 1.0f;
}

- (void) displayLoading:(BOOL)display
{
    if ( display ){
        UIActivityIndicatorView * iv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [iv setFrame:imageRect];
        [iv startAnimating];
        [iv setTag:999];
        [self addSubview:iv];
        [iv release];
    } else {
        UIView * iv = [self viewWithTag:999];
        [iv removeFromSuperview];
    }
}

- (void) updateForPage:(Page *)page thumbnail:(UIImage *)thumbnail
{
    CGFloat screenScale = [UIScreen mainScreen].scale;
    CGSize maxSize = CGSizeMake(self.frame.size.width, MAX_IMAGE_SIZE );
    CGSize newSize = CGSizeZero;
    if ( thumbnail.size.width/thumbnail.size.height > 1.0f ){
        newSize.width = maxSize.width;
        newSize.height = thumbnail.size.height / (thumbnail.size.width/newSize.width);
    } else {
        newSize.height = maxSize.height;
        newSize.width = thumbnail.size.width / (thumbnail.size.height/newSize.height);
    }
    newSize = CGSizeApplyAffineTransform(newSize, CGAffineTransformMakeScale(1/screenScale, 1/screenScale));
    CGImageRef image = [DataWrapper imageWithImage:thumbnail scaledToSize:newSize].CGImage;
    imageRect = CGRectMake((self.frame.size.width-CGImageGetWidth(image))/2,60,CGImageGetWidth(image),CGImageGetHeight(image));
    int c = page.notes.count;
    NSString * notesString = c == 0 ? NSLocalizedString(@"PAGELIST_NOTES_NONOTES",nil) : c > 1 ? [NSString stringWithFormat:NSLocalizedString(@"PAGELIST_NOTES_NOTES",nil),c] : NSLocalizedString(@"PAGELIST_NOTES_ONENOTE",nil);    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.imageLayer.contents = (id)image;
    self.imageLayer.frame = imageRect;
    if ( USE_SHADOW ){
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:imageRect].CGPath;
    }
    //self.textLayer.string = [NSString stringWithFormat:@"%@\n%@",page.name,notesString];
    [CATransaction commit];
    [(UILabel *)[self viewWithTag:123] setText:page.name];
    [(UILabel *)[self viewWithTag:143] setText:notesString];
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(0, 0, 200, 250)];
    if ( self ){
        
        [self setImageLayer:[CALayer layer]];
        imageLayer.anchorPoint = CGPointZero;
        imageLayer.bounds = self.bounds;
        imageLayer.backgroundColor = [UIColor clearColor].CGColor;
        //imageLayer.shouldRasterize = YES;
        [self.layer addSublayer:imageLayer];
        
		UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 220, CGRectGetWidth(self.bounds), 20)];
		//[label setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
		[label setTag:123];
        [label setFont:[UIFont boldSystemFontOfSize:14.0f]];
		[label setTextColor:[UIColor whiteColor]];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:1];
        [label setShadowColor:[UIColor colorWithWhite:0 alpha:0.5]];
        [label setShadowOffset:CGSizeMake(-1, -1)];
        
        
		UILabel * notesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 240, CGRectGetWidth(self.bounds), 20)];
		[notesLabel setTag:143];
        [notesLabel setFont:[UIFont systemFontOfSize:14.0f]];
		[notesLabel setTextColor:[UIColor whiteColor]];
		[notesLabel setBackgroundColor:[UIColor clearColor]];
		[notesLabel setTextAlignment:NSTextAlignmentCenter];
        [notesLabel setNumberOfLines:1];
        [notesLabel setShadowColor:[UIColor colorWithWhite:0 alpha:0.5]];
        [notesLabel setShadowOffset:CGSizeMake(-1, -1)];
        
        [self addSubview:label];
        [self addSubview:notesLabel];
        [label release];
        [notesLabel release];
        
        if ( USE_SHADOW ){
            self.layer.shadowColor = [UIColor blackColor].CGColor;
            self.layer.shadowRadius = 8.0f;
            self.layer.shadowOffset = CGSizeZero;
            self.layer.shadowOpacity = 0.7f;
            self.layer.shadowPath = NULL;
        }
        
    }
    return self;
}

@end

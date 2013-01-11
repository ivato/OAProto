//
//  NavigationPanel.m
//  OAProto
//
//  Created by Ivan Touzeau on 17/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "NavigationPanel.h"
#import <QuartzCore/QuartzCore.h>

#define SHADOW_HEIGHT           100.0f

@implementation NavigationPanel

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super initWithCoder:aDecoder] ){
        [self setBottomShadow:[CALayer layer]];
        _bottomShadow = [CALayer layer];
        _bottomShadow.anchorPoint = CGPointZero;
        _bottomShadow.contents = (id)[UIImage imageNamed:@"gradient_up_10x100.png"].CGImage;
        [self setTopShadow:[CALayer layer]];
        _topShadow.anchorPoint = CGPointZero;
        _topShadow.contents = (id)[UIImage imageNamed:@"gradient_down_10x100.png"].CGImage;
        _topShadow.opacity = _bottomShadow.opacity = 0.75f;
        [self.layer addSublayer:_topShadow];
        [self.layer addSublayer:_bottomShadow];
        
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _topShadow.bounds = CGRectMake(0, self.frame.size.height-SHADOW_HEIGHT, self.frame.size.width, SHADOW_HEIGHT);
    _topShadow.position = CGPointMake(0,0);
    _bottomShadow.bounds = CGRectMake(0, 0, self.frame.size.width, SHADOW_HEIGHT);
    _bottomShadow.position = CGPointMake(0,self.frame.size.height-SHADOW_HEIGHT+44.0f);
}

@end
